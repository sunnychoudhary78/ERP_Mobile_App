class UserDetails {
  String? id;
  String? userId;
  String? associatesName;
  String? payrollCode;
  String? designation;
  String? departmentId;
  String? departmentName;
  String? email;
  String? profilePicture;
  String? companyId;
  String? companyName;
  String? companyLogoFilename;
  String? roleId;
  bool? active;
  DateTime? createdAt;
  DateTime? subscriptionEndDate;

  UserDetails({
    this.id,
    this.userId,
    this.associatesName,
    this.payrollCode,
    this.designation,
    this.departmentId,
    this.departmentName,
    this.email,
    this.profilePicture,
    this.companyId,
    this.companyName,
    this.companyLogoFilename,
    this.roleId,
    this.active,
    this.createdAt,
    this.subscriptionEndDate,
  });

  UserDetails.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    userId = (json['user_id'] ?? json['userId'])?.toString();

    // Real /auth/me response uses "name" at the top level, not
    // "associates_name" — keep both so this survives a future backend change.
    associatesName = (json['associates_name'] ?? json['name'])?.toString();

    payrollCode = (json['payroll_code'] ?? json['payrollCode'])?.toString();

    final roleJson = json['role'];
    designation = (json['designation'] ??
            (roleJson is Map ? roleJson['name'] : null))
        ?.toString();

    // Real response sends a flat "departmentId", not a nested
    // "department": {id, name} object.
    final departmentJson = json['department'];
    departmentId = (departmentJson is Map ? departmentJson['id'] : null)
            ?.toString() ??
        json['departmentId']?.toString();
    departmentName = (departmentJson is Map ? departmentJson['name'] : null)
            ?.toString() ??
        json['departmentName']?.toString();

    email = json['email']?.toString();
    profilePicture =
        (json['profile_picture'] ?? json['profilePicture'])?.toString();

    // Real response uses "companyId" (camelCase), not "company_id".
    companyId = (json['company_id'] ?? json['companyId'])?.toString();
    companyName =
        (json['company']?['name'] ?? json['companyName'])?.toString();
    companyLogoFilename =
        (json['company']?['logo_filename'] ?? json['companyLogoFilename'])
            ?.toString();

    roleId = json['roleId']?.toString();
    active = json['active'] as bool?;
    createdAt = _parseDate(json['created_at'] ?? json['createdAt']);
    subscriptionEndDate = _parseDate(
      json['company']?['subscription_end_date'] ??
          json['subscription_end_date'],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}