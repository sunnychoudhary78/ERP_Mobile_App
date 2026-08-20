class SalesQuote {
  final String id;
  final String? dbId;
  final String? number;
  final String? leadId;
  final String? account;
  final double amount;
  final double subtotal;
  final double gstRate;
  final double gstAmount;
  final String gstNumber;
  final String status;
  final String? validUntil;
  final String owner;
  final List<dynamic> lines;
  final Map<String, dynamic> approval;
  final String notes;
  final String? sentAt;
  final String? createdAt;

  // ── Commercial terms (see Sales_CRM_Commercial_Terms_APIs.md) ──
  final String paymentTermKey;
  final String paymentTerms;
  final String deliveryTerm;
  final Map<String, dynamic> transport;

  const SalesQuote({
    required this.id,
    this.dbId,
    this.number,
    this.leadId,
    this.account,
    required this.amount,
    required this.subtotal,
    required this.gstRate,
    required this.gstAmount,
    required this.gstNumber,
    required this.status,
    this.validUntil,
    required this.owner,
    required this.lines,
    required this.approval,
    required this.notes,
    this.sentAt,
    this.createdAt,
    this.paymentTermKey = 'net_30',
    this.paymentTerms = '',
    this.deliveryTerm = 'buyer',
    this.transport = const {
      'mode': 'client',
      'dispatch': 'deliver',
      'charge': 0,
      'notes': '',
    },
  });

  bool get hasPendingApproval {
    final s = approval['status']?.toString().toLowerCase();

    return approval['required'] == true &&
        (s == 'pending' ||
            s == 'requested' ||
            s == 'pending_manager' ||
            s == 'pending_executive');
  }

  factory SalesQuote.fromJson(Map<String, dynamic> json) {
    return SalesQuote(
      id: json['id']?.toString() ?? '',
      dbId: json['_id']?.toString(),
      number: json['number']?.toString(),
      leadId: json['leadId']?.toString(),
      account: json['account']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0,
      gstNumber: json['gstNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      validUntil: json['validUntil']?.toString(),
      owner: json['owner']?.toString() ?? '',
      lines: json['lines'] is List
          ? List<dynamic>.from(json['lines'] as List)
          : const [],
      approval: json['approval'] is Map
          ? Map<String, dynamic>.from(json['approval'] as Map)
          : const {},
      notes: json['notes']?.toString() ?? '',
      sentAt: json['sentAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      paymentTermKey: json['paymentTermKey']?.toString() ?? 'net_30',
      paymentTerms: json['paymentTerms']?.toString() ?? '',
      deliveryTerm: json['deliveryTerm']?.toString() ?? 'buyer',
      transport: json['transport'] is Map
          ? Map<String, dynamic>.from(json['transport'] as Map)
          : const {
              'mode': 'client',
              'dispatch': 'deliver',
              'charge': 0,
              'notes': '',
            },
    );
  }
}
