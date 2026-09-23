class PurchaseBill {
  final Map<String, dynamic> raw;
  const PurchaseBill(this.raw);

  int get id => _int(raw['id']);
  int? get purchaseId => _nullableInt(raw['purchaseId'] ?? raw['purchase_id']);
  String get billNumber => _text(raw['billNumber'] ?? raw['bill_number']);
  String get status =>
      _text(raw['status']).isEmpty ? 'UNKNOWN' : _text(raw['status']).toUpperCase();
  double get totalAmount => _double(raw['totalAmount'] ?? raw['total_amount']);

  dynamic operator [](String key) => raw[key];

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static int? _nullableInt(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  static String _text(dynamic v) => v?.toString().trim() ?? '';
}

/// Wraps `GET /api/bills` so callers can quickly check which purchase
/// orders already have a bill (drives the "Create bill" button state).
class PurchaseBills {
  final List<PurchaseBill> bills;
  const PurchaseBills(this.bills);

  factory PurchaseBills.fromResponse(dynamic response) {
    final envelope =
        response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
    final payload = envelope['data'];
    final rows = payload is List
        ? payload
        : (payload is Map && payload['data'] is List)
            ? payload['data'] as List
            : (payload is Map && payload['items'] is List)
                ? payload['items'] as List
                : const [];
    return PurchaseBills(
      rows.whereType<Map>().map((r) => PurchaseBill(Map<String, dynamic>.from(r))).toList(),
    );
  }

  Set<int> get billedPurchaseIds =>
      bills.map((b) => b.purchaseId).whereType<int>().toSet();
}