class SalesBill {
  final String id;
  final String? dbId;
  final String? number;
  final String? leadId;
  final String? quoteId;
  final String? account;
  final double amount;
  final double receivedAmount;
  final double creditedAmount;
  final double balanceAmount;
  final String status;
  final String? dueDate;
  final String owner;
  final String notes;
  final String? sentAt;
  final String? paidAt;
  final String? createdAt;

  const SalesBill({
    required this.id,
    this.dbId,
    this.number,
    this.leadId,
    this.quoteId,
    this.account,
    required this.amount,
    required this.receivedAmount,
    required this.creditedAmount,
    required this.balanceAmount,
    required this.status,
    this.dueDate,
    required this.owner,
    required this.notes,
    this.sentAt,
    this.paidAt,
    this.createdAt,
  });

  factory SalesBill.fromJson(Map<String, dynamic> json) {
    return SalesBill(
      id: json['id']?.toString() ?? '',
      dbId: json['_id']?.toString(),
      number: json['number']?.toString(),
      leadId: json['leadId']?.toString(),
      quoteId: json['quoteId']?.toString(),
      account: json['account']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble() ?? 0,
      creditedAmount: (json['creditedAmount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
      dueDate: json['dueDate']?.toString(),
      owner: json['owner']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      sentAt: json['sentAt']?.toString(),
      paidAt: json['paidAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
