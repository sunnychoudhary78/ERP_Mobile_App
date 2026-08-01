class SalesActivity {
  final String id;
  final String? dbId;
  final String? leadId;
  final String? type;
  final String? channel;
  final String subject;
  final String related;
  final String owner;
  final String? dueAt;
  final String status;
  final String notes;
  final String? completedAt;
  final String? createdAt;

  const SalesActivity({
    required this.id,
    this.dbId,
    this.leadId,
    this.type,
    this.channel,
    required this.subject,
    required this.related,
    required this.owner,
    this.dueAt,
    required this.status,
    required this.notes,
    this.completedAt,
    this.createdAt,
  });

  factory SalesActivity.fromJson(Map<String, dynamic> json) {
    return SalesActivity(
      id: json['id']?.toString() ?? '',
      dbId: json['_id']?.toString(),
      leadId: json['leadId']?.toString(),
      type: json['type']?.toString(),
      channel: json['channel']?.toString(),
      subject: json['subject']?.toString() ?? '',
      related: json['related']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      dueAt: json['dueAt']?.toString(),
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      completedAt: json['completedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
