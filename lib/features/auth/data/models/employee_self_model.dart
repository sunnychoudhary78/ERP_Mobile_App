/// Self employee record from `GET /api/employees/single`.
///
/// Fields per doc 05 — User & Team Management:
/// `payroll_code`, `designation`, `manager { id, name, email }`,
/// `department`, `contact_primary`, `profile_picture`, `company`.
///
/// NOTE: `vehicle_type` is **not** part of this payload yet — it is read
/// from `GET /api/sales/claims/my/preview` (see `AuthApiService.fetchVehicleType`).
class EmployeeSelf {
  final String? id;
  final String? payrollCode;
  final String? designation;
  final String? department;
  final String? contactPrimary;
  final String? profilePicture;
  final String? companyName;
  final ManagerInfo? manager;

  const EmployeeSelf({
    this.id,
    this.payrollCode,
    this.designation,
    this.department,
    this.contactPrimary,
    this.profilePicture,
    this.companyName,
    this.manager,
  });

  factory EmployeeSelf.fromJson(Map<String, dynamic> json) {
    final departmentJson = json['department'];
    final managerJson = json['manager'];
    final companyJson = json['company'];

    return EmployeeSelf(
      id: json['id']?.toString(),
      payrollCode:
          (json['payroll_code'] ?? json['payrollCode'])?.toString(),
      designation: (json['designation'] ?? json['designation_name'])
          ?.toString(),
      department: departmentJson is Map
          ? departmentJson['name']?.toString()
          : (json['department'] ?? json['department_name'])?.toString(),
      contactPrimary:
          (json['contact_primary'] ?? json['contactPrimary'])?.toString(),
      profilePicture:
          (json['profile_picture'] ?? json['profilePicture'])?.toString(),
      companyName: companyJson is Map
          ? companyJson['name']?.toString()
          : json['company']?.toString(),
      manager: managerJson is Map
          ? ManagerInfo.fromJson(Map<String, dynamic>.from(managerJson))
          : null,
    );
  }
}

class ManagerInfo {
  final String? id;
  final String? name;
  final String? email;

  const ManagerInfo({this.id, this.name, this.email});

  factory ManagerInfo.fromJson(Map<String, dynamic> json) {
    return ManagerInfo(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}
