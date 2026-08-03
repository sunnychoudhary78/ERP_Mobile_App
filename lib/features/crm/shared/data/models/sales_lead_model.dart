
// Represents one entry inside a lead's `timeline` array, e.g.
// {"at":"2026-08-03","text":"Follow-up stage started","type":"note"}
class SalesLeadTimelineEntry {
  final String at;
  final String text;
  final String type;

  const SalesLeadTimelineEntry({
    required this.at,
    required this.text,
    required this.type,
  });

  factory SalesLeadTimelineEntry.fromJson(Map<String, dynamic> json) {
    return SalesLeadTimelineEntry(
      at: json['at']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}

class SalesLead {
  final String id;
  final String? dbId;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String address;
  final String gstNumber;
  final String source;
  final String clientType;
  final String? temperature;
  final String? lifecycleStage;
  final String status;
  final String? ownerId;
  final String ownerName;
  final double value;
  final int? score;
  final String requirements;
  final List<dynamic> requirementLines;
  final List<SalesLeadTimelineEntry> timeline;
  final String repeatFrequency;
  final String? lostReason;
  final String? quoteId;
  final String? billId;
  final String? salesOrderId;
  final String? customerId;
  final Map<String, dynamic>? wonApproval;
  final String? lastFollowUpAt;
  final String? nextFollowUpAt;
  final String? createdAt;
  final String? updatedAt;

  const SalesLead({
    required this.id,
    this.dbId,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.address,
    required this.gstNumber,
    required this.source,
    required this.clientType,
    this.temperature,
    this.lifecycleStage,
    required this.status,
    this.ownerId,
    required this.ownerName,
    required this.value,
    this.score,
    required this.requirements,
    required this.requirementLines,
    this.timeline = const [],
    this.repeatFrequency = '',
    this.lostReason,
    this.quoteId,
    this.billId,
    this.salesOrderId,
    this.customerId,
    this.wonApproval,
    this.lastFollowUpAt,
    this.nextFollowUpAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasPendingWonApproval {
    final status = wonApproval?['status']?.toString().toLowerCase();
    return status == 'pending' || status == 'requested';
  }

  factory SalesLead.fromJson(Map<String, dynamic> json) {
    return SalesLead(
      id: json['id']?.toString() ?? '',
      dbId: json['_id']?.toString(),
      companyName: json['companyName']?.toString() ?? '',
      contactName: json['contactName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      gstNumber: json['gstNumber']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Phone',
      clientType: json['clientType']?.toString() ?? 'New',
      temperature: json['temperature']?.toString(),
      lifecycleStage: json['lifecycleStage']?.toString(),
      status: json['status']?.toString() ?? '',
      ownerId: json['ownerId']?.toString(),
      ownerName: json['ownerName']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      score: (json['score'] as num?)?.toInt(),
      requirements: json['requirements']?.toString() ?? '',
      requirementLines: json['requirementLines'] is List
          ? List<dynamic>.from(json['requirementLines'] as List)
          : const [],
      timeline: json['timeline'] is List
          ? (json['timeline'] as List)
              .whereType<Map>()
              .map((e) => SalesLeadTimelineEntry.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      repeatFrequency: json['repeatFrequency']?.toString() ?? '',
      lostReason: json['lostReason']?.toString(),
      quoteId: json['quoteId']?.toString(),
      billId: json['billId']?.toString(),
      salesOrderId: json['salesOrderId']?.toString(),
      customerId: json['customerId']?.toString(),
      wonApproval: json['wonApproval'] is Map
          ? Map<String, dynamic>.from(json['wonApproval'] as Map)
          : null,
      lastFollowUpAt: json['lastFollowUpAt']?.toString(),
      nextFollowUpAt: json['nextFollowUpAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}