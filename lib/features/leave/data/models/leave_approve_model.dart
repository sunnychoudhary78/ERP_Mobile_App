class ManagerLeaveRequest {
  final String id;
  final String status;
  final String startDate;
  final String endDate;
  final double days;
  final bool isHalfDay;
  final String? halfDayPart;
  final String reason;
  final String leaveType;
  final String employeeName;
  final String employeeCode;
  final String designation;
  final String department;
  final String profilePicture;
  final List<Map<String, dynamic>> requestedDates;
  final List<String> revocationRequestedDates;

  ManagerLeaveRequest({
    required this.id,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.isHalfDay,
    this.halfDayPart,
    required this.reason,
    required this.leaveType,
    required this.employeeName,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.profilePicture,
    required this.requestedDates,
    required this.revocationRequestedDates,
  });

  factory ManagerLeaveRequest.fromJson(Map<String, dynamic> json) {
    final start = json['startDate']?.toString() ?? '';
    final end = json['endDate']?.toString() ?? '';

    final requestedDatesJson = json['requestedDates'] as List? ?? const [];
    final requestedDates = requestedDatesJson.map<Map<String, dynamic>>((e) {
      if (e is Map) {
        return {
          'date': e['date'],
          'halfDayPart': e['halfDayPart'],
        };
      }
      return {'date': e.toString(), 'halfDayPart': null};
    }).toList();

    double calculatedDays = 1;
    if (requestedDates.isNotEmpty) {
      calculatedDays = requestedDates.length.toDouble();
    } else if (json['isHalfDay'] == true) {
      calculatedDays = 0.5;
    } else if (start.isNotEmpty && end.isNotEmpty) {
      final startDate = DateTime.tryParse(start);
      final endDate = DateTime.tryParse(end);
      if (startDate != null && endDate != null) {
        calculatedDays = endDate.difference(startDate).inDays + 1;
      }
    }

    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final detail = user?['employee_detail'] is Map
        ? Map<String, dynamic>.from(user!['employee_detail'] as Map)
        : null;
    final leaveTypeRaw = json['leave_type'] ?? json['leaveType'];

    return ManagerLeaveRequest(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startDate: start,
      endDate: end,
      days: calculatedDays,
      isHalfDay: json['isHalfDay'] == true,
      halfDayPart: json['halfDayPart']?.toString(),
      reason: json['reason']?.toString() ?? '',
      leaveType: leaveTypeRaw is Map
          ? leaveTypeRaw['name']?.toString() ?? ''
          : leaveTypeRaw?.toString() ?? '',
      employeeName: user?['name']?.toString() ?? '',
      employeeCode: detail?['payroll_code']?.toString() ?? '',
      designation: detail?['designation']?.toString() ?? '',
      department: detail?['department_name']?.toString() ?? '',
      profilePicture: detail?['profile_picture']?.toString() ?? '',
      requestedDates: requestedDates,
      revocationRequestedDates: (json['revocationRequestedDates'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
