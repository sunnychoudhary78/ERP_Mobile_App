class PurchaseOrder {
  final Map<String, dynamic> raw;

  const PurchaseOrder(this.raw);

  int get id => _int(raw['id']);
  String get poNumber => _text(raw['poNumber'] ?? raw['po_number']);
  String get status => _text(raw['status']).isEmpty
      ? 'UNKNOWN'
      : _text(raw['status']).toUpperCase();
  double get totalAmount => _double(raw['totalAmount'] ?? raw['total_amount']);
  String? get createdAt => _nullableText(raw['createdAt'] ?? raw['created_at']);
  String? get updatedAt => _nullableText(raw['updatedAt'] ?? raw['updated_at']);

  int get vendorId => _int(raw['vendorId'] ?? raw['vendor_id']);
  String get vendorName {
    final vendor = raw['vendor'];
    return vendor is Map
        ? _text(vendor['name'])
        : _text(raw['vendorName'] ?? raw['vendor_name']);
  }

  int get warehouseId => _int(raw['warehouseId'] ?? raw['warehouse_id']);
  String get warehouseName {
    final warehouse = raw['warehouse'];
    return warehouse is Map
        ? _text(warehouse['name'])
        : _text(raw['warehouseName'] ?? raw['warehouse_name']);
  }

  List<Map<String, dynamic>> get items {
    final value = raw['items'] ?? raw['lines'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  dynamic operator [](String key) => raw[key];

  static int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullableText(dynamic value) =>
      value == null ? null : value.toString();
}

class PagedPurchaseOrders {
  final List<PurchaseOrder> orders;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PagedPurchaseOrders({
    required this.orders,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PagedPurchaseOrders.fromResponse(dynamic response) {
    final envelope = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final payload = envelope['data'];
    final data = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final rows = payload is List
        ? payload
        : data['data'] is List
        ? data['data'] as List
        : data['items'] is List
        ? data['items'] as List
        : const [];
    final pagination = data['pagination'] is Map
        ? Map<String, dynamic>.from(data['pagination'] as Map)
        : envelope['pagination'] is Map
        ? Map<String, dynamic>.from(envelope['pagination'] as Map)
        : const <String, dynamic>{};
    final parsed = rows
        .whereType<Map>()
        .map((row) => PurchaseOrder(Map<String, dynamic>.from(row)))
        .toList();
    final page = _int(pagination['page'], 1);
    final limit = _int(pagination['limit'], parsed.length);
    final total = _int(pagination['total'], parsed.length);
    final totalPages = _int(
      pagination['totalPages'],
      limit > 0 ? (total / limit).ceil() : 1,
    );
    return PagedPurchaseOrders(
      orders: parsed,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static int _int(dynamic value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}
