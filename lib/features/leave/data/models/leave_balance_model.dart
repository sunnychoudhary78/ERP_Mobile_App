class LeaveBalance {
  final String id;
  final String leaveTypeId;
  final double available;
  final double carried;
  final double pendingReserved;
  final String name;
  final bool allowHalfDay;
  final bool allowNegativeBalance;
  final bool documentRequired;

  LeaveBalance({
    required this.id,
    required this.leaveTypeId,
    required this.available,
    required this.carried,
    required this.pendingReserved,
    required this.name,
    required this.allowHalfDay,
    required this.allowNegativeBalance,
    required this.documentRequired,
  });

  bool get canApply => allowNegativeBalance || available > 0;

  factory LeaveBalance.fromJson(
    Map<String, dynamic> json, [
    Map<String, dynamic>? leaveType,
  ]) {
    final type = leaveType ??
        (json['leave_type'] is Map
            ? Map<String, dynamic>.from(json['leave_type'] as Map)
            : null);

    return LeaveBalance(
      id: json['id']?.toString() ?? '',
      leaveTypeId: json['leave_type_id']?.toString() ??
          json['leaveTypeId']?.toString() ??
          '',
      available: (json['available'] as num?)?.toDouble() ?? 0,
      carried: (json['carried'] as num?)?.toDouble() ?? 0,
      pendingReserved: (json['pending_reserved'] as num?)?.toDouble() ??
          (json['pendingReserved'] as num?)?.toDouble() ??
          0,
      name: type?['name']?.toString() ?? '',
      allowHalfDay: type?['allowHalfDay'] == true ||
          type?['allow_half_day'] == true,
      allowNegativeBalance: type?['allowNegativeBalance'] == true ||
          type?['allow_negative_balance'] == true,
      documentRequired: type?['documentRequired'] == true ||
          type?['document_required'] == true,
    );
  }
}
