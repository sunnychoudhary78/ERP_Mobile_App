class LeaveDetails {
  final String id;
  final String reference;
  final String status;
  final String startDate;
  final String endDate;
  final double days;
  final String? leaveType;
  final String? reason;
  final String? managerName;
  final String? managerEmail;
  final DateTime? appliedAt;
  final List<LeaveHistory> histories;

  const LeaveDetails({
    required this.id,
    required this.reference,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.days,
    this.leaveType,
    this.reason,
    this.managerName,
    this.managerEmail,
    this.appliedAt,
    required this.histories,
  });

  factory LeaveDetails.fromJson(Map<String, dynamic> json) {
    final leaveTypeRaw = json['leaveType'] ?? json['leave_type'];

    return LeaveDetails(
      id: json['id']?.toString() ?? '',
      reference: json['refId']?.toString() ??
          json['humanReadableId']?.toString() ??
          '-',
      status: json['status']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      days: (json['days'] is num) ? (json['days'] as num).toDouble() : 0,
      leaveType: leaveTypeRaw is Map
          ? leaveTypeRaw['name']?.toString()
          : leaveTypeRaw?.toString(),
      reason: json['reason']?.toString(),
      managerName: json['manager'] is Map
          ? json['manager']['name']?.toString()
          : null,
      managerEmail: json['manager'] is Map
          ? json['manager']['email']?.toString()
          : null,
      appliedAt: json['appliedAt'] != null
          ? DateTime.tryParse(json['appliedAt'].toString())
          : null,
      histories: (json['histories'] as List?)
              ?.map((e) => LeaveHistory.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}

class LeaveHistory {
  final String action;
  final String? comment;
  final DateTime? at;
  final String? actorName;

  LeaveHistory({
    required this.action,
    this.comment,
    this.at,
    this.actorName,
  });

  factory LeaveHistory.fromJson(Map<String, dynamic> json) {
    return LeaveHistory(
      action: json['action']?.toString() ?? '',
      comment: json['comment']?.toString(),
      at: json['at'] != null ? DateTime.tryParse(json['at'].toString()) : null,
      actorName: json['actor'] is Map
          ? json['actor']['name']?.toString()
          : null,
    );
  }
}
