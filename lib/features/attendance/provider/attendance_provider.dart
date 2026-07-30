import 'package:erp_app/features/attendance/data/attendance_api_services.dart';
import 'package:erp_app/features/attendance/provider/attendance_auth_provider.dart';
import 'package:erp_app/features/attendance/provider/attendance_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';


final attendanceProvider =
    NotifierProvider<AttendanceNotifier, AttendanceState>(
  AttendanceNotifier.new,
);

class AttendanceNotifier extends Notifier<AttendanceState> {
  late final AttendanceApiService _api;

  @override
  AttendanceState build() {
    _api = ref.read(attendanceApiServiceProvider);
    Future.microtask(_init);
    return const AttendanceState();
  }

  Future<void> _init() async {
    await Future.wait([_loadConfig(), refreshStatus()]);
  }

  Future<void> _loadConfig() async {
    final config = await _api.fetchMobileConfig();
    state = state.copyWith(config: config);
  }

  Future<void> refreshStatus() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final session = await _api.fetchTodayStatus();
      state = state.copyWith(
        isLoading: false,
        todaySession: session,
        clearSession: session == null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _clean(e));
    }
  }

  Future<bool> punchIn({
    XFile? selfie,
    bool remoteRequested = false,
    String? remoteReason,
  }) async {
    if (state.config.requireMobileCheckinSelfie && selfie == null) {
      state = state.copyWith(
        errorMessage: 'Selfie is required for check-in.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearMessages: true);

    Position? pos;
    try {
      pos = await _resolveLocation();
    } catch (e) {
      if (state.config.requireMobileGps) {
        state = state.copyWith(isSubmitting: false, errorMessage: _clean(e));
        return false;
      }
      // GPS not compulsory for this company — proceed without it.
    }

    try {
      final session = await _api.checkIn(
        lat: pos?.latitude,
        lng: pos?.longitude,
        accuracy: pos?.accuracy,
        selfie: selfie,
        remoteRequested: remoteRequested,
        remoteReason: remoteReason,
      );
      state = state.copyWith(
        isSubmitting: false,
        todaySession: session,
        successMessage: 'Punched in successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: _clean(e));
      return false;
    }
  }

  Future<bool> punchOut({XFile? selfie}) async {
    if (state.config.requireMobileCheckoutSelfie && selfie == null) {
      state = state.copyWith(
        errorMessage: 'Selfie is required for check-out.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearMessages: true);

    Position? pos;
    try {
      pos = await _resolveLocation();
    } catch (e) {
      if (state.config.requireMobileGps) {
        state = state.copyWith(isSubmitting: false, errorMessage: _clean(e));
        return false;
      }
    }

    try {
      final session = await _api.checkOut(
        lat: pos?.latitude,
        lng: pos?.longitude,
        accuracy: pos?.accuracy,
        selfie: selfie,
      );
      state = state.copyWith(
        isSubmitting: false,
        todaySession: session,
        successMessage: 'Punched out successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: _clean(e));
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  Future<Position> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please turn on location/GPS to punch in.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required. Enable it from app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}