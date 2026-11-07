import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../crm/shared/data/models/sales_visit_model.dart';
import 'models/tracking_model.dart';

/// GPS Field Tracking API client — doc 01.
///
/// Base: `/api/sales/tracking`. Every write requires `sales_tracking.sync`;
/// the session polyline/visits reads require `sales_visits.view`.
///
/// - `POST /sessions/check-in`        start (or resume) today's open session
/// - `POST /sessions/heartbeat`       keep the session alive (every 30–60s)
/// - `POST /sessions/location-off`    OS reported location disabled
/// - `POST /sessions/check-out`       stop tracking
/// - `POST /points/batch`             upload sample points (incl. offline)
/// - `GET  /my-history`               own sessions / KM totals
/// - `GET  /sessions/:id/points`      own session polyline
/// - `GET  /sessions/:id/visits`      visits captured on a session
class TrackingApiService {
  final ApiService api;

  TrackingApiService(this.api);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'data': response};
  }

  Map<String, dynamic> _data(dynamic response) {
    final map = _asMap(response);
    final data = map['data'];
    return data is Map ? Map<String, dynamic>.from(data) : map;
  }

  /// `POST /api/sales/tracking/sessions/check-in`.
  ///
  /// Starts or resumes today's open session. Passing the first GPS fix also
  /// creates the session's first point.
  Future<TrackingSession> checkIn({
    required DeviceInfoPayload deviceInfo,
    TrackingPoint? point,
  }) async {
    final payload = <String, dynamic>{
      if (point != null) ...{
        'latitude': point.latitude,
        'longitude': point.longitude,
        if (point.accuracy != null) 'accuracy': point.accuracy,
        if (point.speed != null) 'speed': point.speed,
        if (point.heading != null) 'heading': point.heading,
        'recorded_at': point.recordedAt,
      },
      'device_info': deviceInfo.toJson(),
    };

    debugPrint('=== TRACKING CHECK-IN ===');
    debugPrint(payload.toString());

    final response = await api.post(ApiEndpoints.salesTrackingCheckIn, payload);
    final map = _asMap(response);
    final data = _data(response);
    final raw = data['session'] ?? map['session'] ?? data;
    return TrackingSession.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : data,
    );
  }

  /// `POST /api/sales/tracking/sessions/heartbeat`.
  ///
  /// Throws [ApiException] (HTTP 400, "No open tracking session") when the
  /// session was auto-closed — the controller treats that as stopped.
  Future<String?> heartbeat({required DeviceInfoPayload deviceInfo}) async {
    final response = await api.post(
      ApiEndpoints.salesTrackingHeartbeat,
      {'device_info': deviceInfo.toJson()},
    );
    final data = _data(response);
    return (data['sessionId'] ?? data['session_id'])?.toString();
  }

  /// `POST /api/sales/tracking/sessions/location-off`.
  ///
  /// [reason] is one of `location_off`, `permission_denied`, `gps_signal_lost`.
  Future<void> locationOff({required String reason}) async {
    await api.post(
      ApiEndpoints.salesTrackingLocationOff,
      {'reason': reason},
    );
  }

  /// `POST /api/sales/tracking/sessions/check-out`.
  ///
  /// [sessionId] is optional — the server falls back to the open session.
  Future<TrackingSession?> checkOut({String? sessionId}) async {
    final response = await api.post(
      ApiEndpoints.salesTrackingCheckOut,
      <String, dynamic>{
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      },
    );
    final data = _data(response);
    final raw = data['session'] ?? data;
    if (raw is Map && raw.isNotEmpty && raw['id'] != null) {
      return TrackingSession.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  /// `POST /api/sales/tracking/points/batch`.
  ///
  /// Returns the number of points the server actually stored (`count`).
  /// Dropped: accuracy > 80 m, invalid lat/lng, duplicates.
  Future<int> uploadPoints({
    required List<TrackingPoint> points,
    String? sessionId,
  }) async {
    if (points.isEmpty) return 0;

    final payload = <String, dynamic>{
      if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      'points': points.map((p) => p.toUploadJson()).toList(),
    };

    final response = await api.post(
      ApiEndpoints.salesTrackingPointsBatch,
      payload,
    );
    final data = _data(response);
    final count = data['count'];
    if (count is num) return count.toInt();
    return int.tryParse(count?.toString() ?? '') ?? points.length;
  }

  /// `GET /api/sales/tracking/my-history`.
  ///
  /// Newest first. [status] is `open` or `closed`; [limit] is capped at 500.
  Future<List<TrackingSession>> myHistory({
    DateTime? from,
    DateTime? to,
    String? status,
    int? limit,
  }) async {
    final response = await api.get(
      ApiEndpoints.salesTrackingMyHistory,
      queryParams: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': ?limit,
      },
    );

    final map = _asMap(response);
    final data = _data(response);
    final raw = data['sessions'] ?? map['sessions'] ?? data['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => TrackingSession.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `GET /api/sales/tracking/sessions/:id/points?route=road`.
  Future<TrackingPointsResult> sessionPoints(
    String id, {
    bool road = false,
  }) async {
    final response = await api.get(
      ApiEndpoints.salesTrackingSessionPoints(id),
      queryParams: {if (road) 'route': 'road'},
    );

    final data = _data(response);
    final raw = data['points'];
    final points = raw is List
        ? raw
              .whereType<Map>()
              .map((e) => TrackingPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <TrackingPoint>[];
    return TrackingPointsResult(points: points, route: data['route']);
  }

  /// `GET /api/sales/tracking/sessions/:id/visits`.
  Future<List<SalesVisit>> sessionVisits(String id) async {
    final response = await api.get(ApiEndpoints.salesTrackingSessionVisits(id));
    final data = _data(response);
    final raw = data['visits'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => SalesVisit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Optional `GET /api/sales/tracking/dashboard` — today's shortcut numbers
  /// (needs `sales_visits.view` or `sales_tracking.view`).
  Future<TrackingDashboardSummary> dashboard() async {
    final response = await api.get(ApiEndpoints.salesTrackingDashboard);
    return TrackingDashboardSummary.fromJson(_data(response));
  }
}
