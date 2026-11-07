import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../crm/shared/data/models/sales_visit_model.dart';
import '../../../crm/shared/presentation/providers/sales_workspace_provider.dart';
import '../../data/models/tracking_model.dart';
import '../../data/tracking_api_service.dart';
import '../../services/tracking_foreground_service.dart';

final trackingApiProvider = Provider<TrackingApiService>((ref) {
  return TrackingApiService(ref.read(apiServiceProvider));
});

/// Server-side accuracy cut-off (doc 01) — points worse than this are dropped
/// both on device and by the backend.
const double kTrackingMaxAccuracyMeters = 80;

/// Snapshot of the field-tracking controller.
class TrackingState {
  final bool isTracking;
  final TrackingSession? openSession;
  final double todayKm;
  final int todayVisits;
  final TrackingPoint? lastPoint;
  final int queuedPoints;
  final bool locationEnabled;
  final String? banner;
  final String? error;
  final bool isStarting;
  final bool isStopping;

  const TrackingState({
    this.isTracking = false,
    this.openSession,
    this.todayKm = 0,
    this.todayVisits = 0,
    this.lastPoint,
    this.queuedPoints = 0,
    this.locationEnabled = true,
    this.banner,
    this.error,
    this.isStarting = false,
    this.isStopping = false,
  });

  TrackingState copyWith({
    bool? isTracking,
    TrackingSession? openSession,
    bool clearSession = false,
    double? todayKm,
    int? todayVisits,
    TrackingPoint? lastPoint,
    int? queuedPoints,
    bool? locationEnabled,
    String? banner,
    String? error,
    bool clearBanner = false,
    bool clearError = false,
    bool? isStarting,
    bool? isStopping,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      openSession: clearSession ? null : (openSession ?? this.openSession),
      todayKm: todayKm ?? this.todayKm,
      todayVisits: todayVisits ?? this.todayVisits,
      lastPoint: lastPoint ?? this.lastPoint,
      queuedPoints: queuedPoints ?? this.queuedPoints,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      banner: clearBanner ? null : (banner ?? this.banner),
      error: clearError ? null : (error ?? this.error),
      isStarting: isStarting ?? this.isStarting,
      isStopping: isStopping ?? this.isStopping,
    );
  }
}

final trackingControllerProvider =
    NotifierProvider<TrackingController, TrackingState>(TrackingController.new);

/// Owns the whole GPS day: start / heartbeat / point upload / location-off /
/// stop, the offline point queue, and the "is a session open?" restore.
///
/// Point sampling, heartbeat (45s) and queue flush (30s) run only while a
/// session is open. The queue and the open session id are persisted so an app
/// kill never loses points — they flush on the next run.
class TrackingController extends Notifier<TrackingState> {
  static const _kOpenSession = 'tracking.open_session';
  static const _kQueue = 'tracking.points_queue';
  static const _appVersion = '1.0.0';
  static const _maxBatch = 100;

  late final TrackingApiService _api;
  late final SharedPreferences _prefs;

  final List<TrackingPoint> _queue = <TrackingPoint>[];
  StreamSubscription<Position>? _posSub;
  Timer? _heartbeatTimer;
  Timer? _flushTimer;
  Timer? _locationTimer;
  bool _flushInProgress = false;
  bool _locationOffSent = false;
  bool _autoSyncStarted = false;

  @override
  TrackingState build() {
    _api = ref.read(trackingApiProvider);
    _prefs = ref.read(sharedPreferencesProvider);

    _restoreQueue();
    final saved = _restoreSession();

    ref.onDispose(_cancelTimers);

    return TrackingState(
      openSession: saved,
      isTracking: saved?.isOpen ?? false,
      queuedPoints: _queue.length,
    );
  }

  // ───────────────────────── Public API ─────────────────────────

  /// Fetches the open session (if any) so an app reopen restores tracking
  /// without creating a second session. Safe to call repeatedly.
  Future<void> syncWithServer() async {
    if (_autoSyncStarted) return;
    _autoSyncStarted = true;
    try {
      final sessions = await _api.myHistory(status: 'open', limit: 5);
      final open = sessions.where((s) => s.isOpen).toList();
      final session = open.isNotEmpty ? open.first : null;

      if (session != null) {
        await _persistSession(session);
        state = state.copyWith(
          isTracking: true,
          openSession: session,
          clearBanner: true,
        );
        _startStreams();
      } else if (state.isTracking) {
        // Our stored session was auto-closed server-side (midnight cron).
        await _clearSession();
        _cancelTimers();
        state = state.copyWith(
          isTracking: false,
          clearSession: true,
          banner: 'Your session was closed. Tap Start to begin a new day.',
        );
      }
    } catch (e) {
      debugPrint('Tracking sync failed: $e');
    }
    await refreshToday();
  }

  /// Reloads today's KM + visit count.
  Future<void> refreshToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final sessions = await _api.myHistory(from: startOfDay, to: now);
      final km = sessions.fold<double>(0, (sum, s) => sum + s.totalDistanceKm);
      state = state.copyWith(todayKm: km);
    } catch (e) {
      debugPrint('Tracking today KM failed: $e');
    }

    try {
      final visits = await ref
          .read(salesCrmApiProvider)
          .fetchVisits(from: startOfDay, to: now, limit: 200);
      state = state.copyWith(todayVisits: visits.length);
    } catch (e) {
      debugPrint('Tracking today visits failed: $e');
    }
  }

  /// Starts (or resumes) today's session and begins the GPS loop.
  Future<bool> start() async {
    if (state.isTracking || state.isStarting) return true;
    state = state.copyWith(isStarting: true, clearBanner: true, clearError: true);

    if (!await _ensureLocationReady()) {
      state = state.copyWith(isStarting: false);
      return false;
    }

    TrackingPoint? firstPoint;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (pos.accuracy <= kTrackingMaxAccuracyMeters) {
        firstPoint = _pointFromPosition(pos);
      }
    } catch (e) {
      debugPrint('First fix failed: $e');
    }

    try {
      final session = await _api.checkIn(
        deviceInfo: _deviceInfo(),
        point: firstPoint,
      );
      await _persistSession(session);
      state = state.copyWith(
        isStarting: false,
        isTracking: true,
        openSession: session,
        clearBanner: true,
        clearError: true,
      );
      _startStreams();
      await refreshToday();
      return true;
    } catch (e) {
      state = state.copyWith(isStarting: false, error: _clean(e));
      return false;
    }
  }

  /// Flushes the queue, checks out, and stops the GPS loop.
  Future<bool> stop() async {
    if (state.isStopping) return false;
    state = state.copyWith(isStopping: true, clearBanner: true, clearError: true);

    await _flushQueue(force: true);

    try {
      await _api.checkOut(sessionId: state.openSession?.id);
    } catch (e) {
      debugPrint('Check-out failed: $e');
      // Report but still stop locally so the user is not stuck.
    }

    await _clearSession();
    _cancelTimers();
    state = state.copyWith(
      isStopping: false,
      isTracking: false,
      clearSession: true,
      locationEnabled: true,
      clearBanner: true,
    );
    await refreshToday();
    return true;
  }

  void clearMessages() {
    state = state.copyWith(clearBanner: true, clearError: true);
  }

  // ───────────────────────── GPS loop ─────────────────────────

  /// 15 m distance filter (doc 01). Android samples every 15 s; iOS keeps
  /// delivering updates while backgrounded (needs "Always" permission).
  LocationSettings _streamSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 15),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
  }

  void _startStreams() {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: _streamSettings(),
    ).listen(_onPosition, onError: (Object e) => debugPrint('GPS error: $e'));

    // Keep the process alive in the background (Android foreground service).
    unawaited(startTrackingService());

    _heartbeatTimer ??= Timer.periodic(
      const Duration(seconds: 45),
      (_) => _heartbeat(),
    );
    _flushTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => _flushQueue(),
    );
    _locationTimer ??= Timer.periodic(
      const Duration(seconds: 20),
      (_) => _watchLocationService(),
    );
  }

  void _cancelTimers() {
    _posSub?.cancel();
    _posSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _locationTimer?.cancel();
    _locationTimer = null;
    _flushInProgress = false;
    _locationOffSent = false;
    unawaited(stopTrackingService());
  }

  TrackingPoint _pointFromPosition(Position pos) => TrackingPoint(
    latitude: pos.latitude,
    longitude: pos.longitude,
    accuracy: pos.accuracy,
    speed: pos.speed,
    heading: pos.heading,
    recordedAt: DateTime.now().toUtc().toIso8601String(),
    isOffline: false,
  );

  void _onPosition(Position pos) {
    // Drop junk before it ever reaches the queue.
    if (pos.accuracy > kTrackingMaxAccuracyMeters) return;

    _queue.add(_pointFromPosition(pos));
    state = state.copyWith(lastPoint: _queue.last, queuedPoints: _queue.length);
    _persistQueue();
  }

  Future<void> _heartbeat() async {
    try {
      await _api.heartbeat(deviceInfo: _deviceInfo());
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        await _handleSessionLost();
      }
    } catch (_) {
      // Transient network issues — retry on the next tick.
    }
  }

  Future<void> _handleSessionLost() async {
    _cancelTimers();
    await _clearSession();
    state = state.copyWith(
      isTracking: false,
      clearSession: true,
      banner: 'Tracking stopped for the day. Start again to resume.',
    );
  }

  Future<void> _watchLocationService() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && !_locationOffSent) {
      _locationOffSent = true;
      state = state.copyWith(
        locationEnabled: false,
        banner: 'Turn location on to keep tracking.',
      );
      try {
        await _api.locationOff(reason: 'location_off');
      } catch (_) {
        // best-effort
      }
    } else if (enabled && _locationOffSent) {
      _locationOffSent = false;
      state = state.copyWith(locationEnabled: true, clearBanner: true);
    }
  }

  /// Uploads queued points in batches. Points are persisted first and only
  /// removed after a successful response (ACK), so nothing is lost offline.
  Future<void> _flushQueue({bool force = false}) async {
    if (_flushInProgress || _queue.isEmpty) return;
    if (!force && state.openSession == null) return;

    _flushInProgress = true;
    try {
      while (_queue.isNotEmpty) {
        final batch = _queue.take(_maxBatch).toList();
        await _api.uploadPoints(
          points: batch,
          sessionId: state.openSession?.id,
        );
        // Persist first, then ACK-delete the uploaded prefix.
        _queue.removeRange(0, batch.length);
        await _persistQueue();
        state = state.copyWith(queuedPoints: _queue.length);
        if (batch.length < _maxBatch) break;
      }
    } catch (e) {
      debugPrint('Point flush failed: $e');
    } finally {
      _flushInProgress = false;
    }
  }

  // ───────────────────────── Helpers ─────────────────────────

  Future<bool> _ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      state = state.copyWith(
        locationEnabled: false,
        banner: 'Turn on location/GPS to start tracking.',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        banner: permission == LocationPermission.deniedForever
            ? 'Enable location permission from app settings to track.'
            : 'Location permission is required to track.',
      );
      return false;
    }

    state = state.copyWith(locationEnabled: true, clearBanner: true);
    return true;
  }

  DeviceInfoPayload _deviceInfo() => DeviceInfoPayload(
    platform: Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : Platform.operatingSystem,
    osVersion: Platform.operatingSystemVersion,
    appVersion: _appVersion,
  );

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  // ───────────────────────── Persistence ─────────────────────────

  void _restoreQueue() {
    final raw = _prefs.getString(_kQueue);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _queue
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((e) => TrackingPoint.fromJson(Map<String, dynamic>.from(e))),
          );
      }
    } catch (e) {
      debugPrint('Queue restore failed: $e');
    }
  }

  TrackingSession? _restoreSession() {
    final raw = _prefs.getString(_kOpenSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return TrackingSession.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('Session restore failed: $e');
    }
    return null;
  }

  Future<void> _persistQueue() async {
    await _prefs.setString(
      _kQueue,
      jsonEncode(_queue.map((p) => p.toStoreJson()).toList()),
    );
  }

  Future<void> _persistSession(TrackingSession session) async {
    await _prefs.setString(_kOpenSession, jsonEncode(session.toJson()));
  }

  Future<void> _clearSession() async {
    await _prefs.remove(_kOpenSession);
  }
}

/// My sessions list — `GET /api/sales/tracking/my-history` (newest first).
final myTrackingSessionsProvider =
    AsyncNotifierProvider<MyTrackingSessionsNotifier, List<TrackingSession>>(
      MyTrackingSessionsNotifier.new,
    );

class MyTrackingSessionsNotifier extends AsyncNotifier<List<TrackingSession>> {
  @override
  Future<List<TrackingSession>> build() async {
    ref.watch(authProvider);
    return ref.read(trackingApiProvider).myHistory(limit: 200);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(trackingApiProvider).myHistory(limit: 200),
    );
  }
}

/// Own session polyline — `GET /api/sales/tracking/sessions/:id/points`.
final sessionPointsProvider = FutureProvider.autoDispose
    .family<TrackingPointsResult, String>((ref, sessionId) {
      ref.watch(authProvider);
      return ref.read(trackingApiProvider).sessionPoints(sessionId);
    });

/// Visits captured on a session — `GET .../sessions/:id/visits`.
final sessionVisitsProvider = FutureProvider.autoDispose
    .family<List<SalesVisit>, String>((ref, sessionId) {
      ref.watch(authProvider);
      return ref.read(trackingApiProvider).sessionVisits(sessionId);
    });
