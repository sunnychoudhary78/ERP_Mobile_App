class LeaveType {
  final String id;
  final String name;
  final bool allowHalfDay;
  final bool allowNegativeBalance;
  final bool documentRequired;
  final bool isActive;

  const LeaveType({
    required this.id,
    required this.name,
    required this.allowHalfDay,
    required this.allowNegativeBalance,
    required this.documentRequired,
    required this.isActive,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      allowHalfDay: json['allowHalfDay'] == true ||
          json['allow_half_day'] == true,
      allowNegativeBalance: json['allowNegativeBalance'] == true ||
          json['allow_negative_balance'] == true,
      documentRequired: json['documentRequired'] == true ||
          json['document_required'] == true,
      isActive: json['isActive'] != false && json['is_active'] != false,
    );
  }
}
