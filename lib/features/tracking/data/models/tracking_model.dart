// Models for the GPS-Based Field Tracking module — doc 01.
//
// Base path: `/api/sales/tracking`. A salesperson checks in at the start of
// the day, streams GPS points (also offline), heartbeats every 30–60s and
// checks out at the end. Only the user's **own** sessions are read here —
// live maps, team replay and Excel reports stay on web.

double _toDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _toBool(dynamic v) => v == true || v == 'true' || v == 1;

/// The `device_info` payload the app attaches to check-in / heartbeat.
class DeviceInfoPayload {
  final String platform; // android | ios
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final String? deviceId;
  final int? batteryPercent;

  const DeviceInfoPayload({
    required this.platform,
    this.manufacturer,
    this.model,
    this.osVersion,
    this.appVersion,
    this.deviceId,
    this.batteryPercent,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'platform': platform,
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (model != null) 'model': model,
    if (osVersion != null) 'os_version': osVersion,
    if (appVersion != null) 'app_version': appVersion,
    if (deviceId != null) 'device_id': deviceId,
    if (batteryPercent != null) 'battery_percent': batteryPercent,
  };
}

/// A tracking session (`status` is `open` or `closed`).
class TrackingSession {
  final String id;
  final String? userId;
  final String? userName;
  final String? checkInAt;
  final String? checkOutAt;
  final String status;
  final double totalDistanceKm;
  final String? lastHeartbeatAt;
  final String? locationOffReason;
  final Map<String, dynamic>? deviceInfo;
  final String? createdAt;

  const TrackingSession({
    required this.id,
    this.userId,
    this.userName,
    this.checkInAt,
    this.checkOutAt,
    this.status = '',
    this.totalDistanceKm = 0,
    this.lastHeartbeatAt,
    this.locationOffReason,
    this.deviceInfo,
    this.createdAt,
  });

  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    final rawDevice = json['deviceInfo'] ?? json['device_info'];
    return TrackingSession(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      userName: (json['userName'] ?? json['user_name'])?.toString(),
      checkInAt: (json['checkInAt'] ?? json['check_in_at'])?.toString(),
      checkOutAt: (json['checkOutAt'] ?? json['check_out_at'])?.toString(),
      status: json['status']?.toString() ?? '',
      totalDistanceKm: _toDouble(
        json['totalDistanceKm'] ?? json['total_distance_km'],
      ),
      lastHeartbeatAt:
          (json['lastHeartbeatAt'] ?? json['last_heartbeat_at'])?.toString(),
      locationOffReason:
          (json['locationOffReason'] ?? json['location_off_reason'])?.toString(),
      deviceInfo: rawDevice is Map
          ? Map<String, dynamic>.from(rawDevice)
          : null,
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'userName': userName,
    'checkInAt': checkInAt,
    'checkOutAt': checkOutAt,
    'status': status,
    'totalDistanceKm': totalDistanceKm,
    'lastHeartbeatAt': lastHeartbeatAt,
    'locationOffReason': locationOffReason,
    'deviceInfo': deviceInfo,
    'createdAt': createdAt,
  };

  bool get isOpen => status.trim().toLowerCase() == 'open';

  DateTime? get checkInTime => DateTime.tryParse(checkInAt ?? '')?.toLocal();
  DateTime? get checkOutTime => DateTime.tryParse(checkOutAt ?? '')?.toLocal();

  /// Duration between check-in and check-out (or now, if still open).
  Duration get duration {
    final start = checkInTime;
    if (start == null) return Duration.zero;
    final end = checkOutTime ?? DateTime.now();
    return end.difference(start);
  }
}

/// A single GPS sample. Upload uses snake_case keys, the server echoes
/// camelCase — [fromJson] accepts both.
class TrackingPoint {
  final String? id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final String recordedAt;
  final bool isOffline;
  final int? batteryPercent;

  const TrackingPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.recordedAt,
    this.isOffline = false,
    this.batteryPercent,
  });

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      id: json['id']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: _toDoubleOrNull(json['accuracy']),
      speed: _toDoubleOrNull(json['speed']),
      heading: _toDoubleOrNull(json['heading']),
      recordedAt:
          (json['recordedAt'] ?? json['recorded_at'])?.toString() ?? '',
      isOffline: _toBool(json['isOffline'] ?? json['is_offline']),
      batteryPercent: _toIntOrNull(
        json['batteryPercent'] ?? json['battery_percent'],
      ),
    );
  }

  /// Body shape for `POST /points/batch` (snake_case per the API contract).
  Map<String, dynamic> toUploadJson() => <String, dynamic>{
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    if (speed != null) 'speed': speed,
    if (heading != null) 'heading': heading,
    'recorded_at': recordedAt,
    'is_offline': isOffline,
    if (batteryPercent != null) 'battery_percent': batteryPercent,
  };

  /// Persisted form used for the offline queue.
  Map<String, dynamic> toStoreJson() => toUploadJson();
}

/// `GET /sessions/:id/points` — stored points plus an optional road-snapped
/// route (`route` is null when Valhalla is disabled on the server).
class TrackingPointsResult {
  final List<TrackingPoint> points;
  final dynamic route;

  const TrackingPointsResult({this.points = const [], this.route});
}

/// `GET /api/sales/tracking/dashboard` — optional shortcut for today's numbers.
class TrackingDashboardSummary {
  final int openSessions;
  final int visitsToday;
  final int openClaims;
  final double kmToday;

  const TrackingDashboardSummary({
    this.openSessions = 0,
    this.visitsToday = 0,
    this.openClaims = 0,
    this.kmToday = 0,
  });

  factory TrackingDashboardSummary.fromJson(Map<String, dynamic> json) {
    return TrackingDashboardSummary(
      openSessions: _toIntOrNull(json['openSessions']) ?? 0,
      visitsToday: _toIntOrNull(json['visitsToday']) ?? 0,
      openClaims: _toIntOrNull(json['openClaims']) ?? 0,
      kmToday: _toDouble(json['kmToday']),
    );
  }
}
