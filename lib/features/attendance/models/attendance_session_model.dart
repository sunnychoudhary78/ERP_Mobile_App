
class AttendanceSession {
  final String? id;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInSelfieUrl;
  final String? checkOutSelfieUrl;
  final String? status;

  const AttendanceSession({
    this.id,
    this.checkInTime,
    this.checkOutTime,
    this.checkInSelfieUrl,
    this.checkOutSelfieUrl,
    this.status,
  });

  bool get isOpen => checkInTime != null && checkOutTime == null;

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return AttendanceSession(
      id: (json['id'] ?? json['_id'])?.toString(),
      checkInTime: parseDate(
        json['checkInTime'] ?? json['checkIn'] ?? json['check_in_time'],
      ),
      checkOutTime: parseDate(
        json['checkOutTime'] ?? json['checkOut'] ?? json['check_out_time'],
      ),
      checkInSelfieUrl: json['checkInSelfie']?.toString(),
      checkOutSelfieUrl: json['checkOutSelfie']?.toString(),
      status: json['status']?.toString(),
    );
  }
}