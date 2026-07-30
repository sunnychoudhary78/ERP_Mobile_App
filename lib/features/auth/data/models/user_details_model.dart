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
  });

  UserDetails.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    userId = json['user_id']?.toString();
    associatesName = json['associates_name']?.toString();
    payrollCode = json['payroll_code']?.toString();
    designation = json['designation']?.toString();
    departmentId = json['department']?['id']?.toString();
    departmentName = json['department']?['name']?.toString();
    email = json['email']?.toString();
    profilePicture = json['profile_picture']?.toString();
    companyId = json['company_id']?.toString();
    companyName = json['company']?['name']?.toString();
    companyLogoFilename = json['company']?['logo_filename']?.toString();
  }
}
