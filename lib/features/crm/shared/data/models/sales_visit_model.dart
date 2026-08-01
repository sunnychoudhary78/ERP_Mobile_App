class SalesVisit {
  final String id;
  final String? dbId;
  final String? repId;
  final String? repName;
  final String clientName;
  final String? type;
  final String location;
  final String? at;
  final String notes;

  const SalesVisit({
    required this.id,
    this.dbId,
    this.repId,
    this.repName,
    required this.clientName,
    this.type,
    required this.location,
    this.at,
    required this.notes,
  });

  factory SalesVisit.fromJson(Map<String, dynamic> json) {
    return SalesVisit(
      id: json['id']?.toString() ?? '',
      dbId: json['_id']?.toString(),
      repId: json['repId']?.toString(),
      repName: json['repName']?.toString(),
      clientName: json['clientName']?.toString() ?? '',
      type: json['type']?.toString(),
      location: json['location']?.toString() ?? '',
      at: json['at']?.toString(),
      notes: json['notes']?.toString() ?? '',
    );
  }
}
