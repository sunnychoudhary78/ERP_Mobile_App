class PurchaseDemand {
  final Map<String, dynamic> raw;

  const PurchaseDemand(this.raw);

  dynamic operator [](String key) => raw[key];

  String get workOrderId => _text(raw['workOrderId'] ?? raw['work_order_id']);

  dynamic get approvalRequestId =>
      raw['approvalRequestId'] ?? raw['approval_request_id'];

  String get status => _text(raw['status']).isEmpty
      ? 'PENDING'
      : _text(raw['status']).toUpperCase();

  List<Map<String, dynamic>> get lines {
    final value = raw['items'] ?? raw['lines'] ?? raw['shortages'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String get title {
    final workOrder = raw['workOrder'];
    if (workOrder is Map) {
      final number = workOrder['workOrderNo'] ?? workOrder['orderNo'];
      if (number != null && '$number'.trim().isNotEmpty) return '$number';
    }
    return workOrderId.isEmpty ? 'Purchase demand' : 'Work order $workOrderId';
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';
}

class PagedPurchaseDemands {
  final List<PurchaseDemand> demands;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PagedPurchaseDemands({
    required this.demands,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PagedPurchaseDemands.fromResponse(dynamic response) {
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
    final parsedRows = rows
        .whereType<Map>()
        .map((row) => PurchaseDemand(Map<String, dynamic>.from(row)))
        .toList();
    final page = _int(pagination['page'], 1);
    final limit = _int(pagination['limit'], parsedRows.length);
    final total = _int(pagination['total'], parsedRows.length);
    final totalPages = _int(
      pagination['totalPages'],
      limit > 0 ? (total / limit).ceil() : 1,
    );
    return PagedPurchaseDemands(
      demands: parsedRows,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static int _int(dynamic value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}
