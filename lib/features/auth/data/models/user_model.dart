class UserModel {
  final String token;
  final User user;

  UserModel({required this.token, required this.user});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token']?.toString() ?? '',
      user: User.fromJson(Map<String, dynamic>.from(json['user'] ?? {})),
    );
  }
}

class Role {
  final String id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String roleId;
  final String companyId;
  final String? companyName;
  final String? departmentId;
  final String? departmentName;
  final Role? role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.roleId,
    required this.companyId,
    this.companyName,
    this.departmentId,
    this.departmentName,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final departmentJson = json['department'];
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      roleId: json['roleId']?.toString() ?? '',
      companyId: json['company']?['id']?.toString() ?? '',
      companyName: json['company']?['name']?.toString(),
      departmentId: departmentJson?['id']?.toString(),
      departmentName: departmentJson?['name']?.toString(),
      role: json['role'] != null
          ? Role.fromJson(Map<String, dynamic>.from(json['role']))
          : null,
    );
  }
}
