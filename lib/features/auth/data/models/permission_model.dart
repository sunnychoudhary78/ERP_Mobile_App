class Permission {
  final String id;
  final String name;
  final String? displayName;
  final String? description;

  Permission({
    required this.id,
    required this.name,
    this.displayName,
    this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      description: json['description']?.toString(),
    );
  }
}