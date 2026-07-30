/// Mirrors GET /api/attendance/mobile-config.
/// Drives which UI affordances (GPS block, selfie capture) show up on the
/// punch screen for this company.
class AttendanceConfig {
  final bool allowMobileCheckin;
  final bool requireMobileGps;
  final bool enforceMobileGeofence;
  final bool requireMobileCheckinSelfie;
  final bool requireMobileCheckoutSelfie;

  const AttendanceConfig({
    this.allowMobileCheckin = true,
    this.requireMobileGps = false,
    this.enforceMobileGeofence = false,
    this.requireMobileCheckinSelfie = false,
    this.requireMobileCheckoutSelfie = false,
  });

  factory AttendanceConfig.fromJson(Map<String, dynamic> json) {
    bool _b(dynamic v, bool fallback) => v is bool ? v : fallback;
    return AttendanceConfig(
      allowMobileCheckin: _b(json['allow_mobile_checkin'], true),
      requireMobileGps: _b(json['require_mobile_gps'], false),
      enforceMobileGeofence: _b(json['enforce_mobile_geofence'], false),
      requireMobileCheckinSelfie:
          _b(json['require_mobile_checkin_selfie'], false),
      requireMobileCheckoutSelfie:
          _b(json['require_mobile_checkout_selfie'], false),
    );
  }
}