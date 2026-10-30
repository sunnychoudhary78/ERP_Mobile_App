/// One row of the manager's "My team" list.
///
/// Sourced from `GET /api/employees/team-dashboard` (doc 05, option A).
/// Read-only — the field app never edits employees.
class TeamMember {
  final String id;
  final String name;
  final String? designation;

  const TeamMember({
    required this.id,
    required this.name,
    this.designation,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    // team-dashboard may nest the employee under `user` or flatten it.
    final user = json['user'];
    final name = json['name'] ??
        (user is Map ? user['name'] : null) ??
        json['employee_name'];

    final designation = json['designation'] ??
        (json['designation_name']);

    return TeamMember(
      id: (json['id'] ?? json['employee_id'] ?? json['user_id'])
              ?.toString() ??
          '',
      name: name?.toString() ?? '—',
      designation: designation?.toString(),
    );
  }
}
