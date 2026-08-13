// dashboard_stats_model.dart

class InventoryDashboardStats {
  final int lotsCount;
  final int stockCount;
  final int productsWithStock;
  final int lowStockCount;
  final int movementIn30d;
  final int movementOut30d;
  final Map<String, GradeBreakdownEntry> gradeBreakdown;
  final List<TopProduct> topProductsByStock;
  final List<RecentMovement> recentMovements;

  final double revenue;
  final int ordersCount;
  final int itemsCount;
  final int customersCount;
  final int vendorsCount;
  final int purchasesCount;
  final double purchasesAmount;
  final int vendorReceivedQty;
  final SummaryCount invoiceSummary;
  final SummaryCount billSummary;
  final int approvalsPendingCount;

  InventoryDashboardStats({
    required this.lotsCount,
    required this.stockCount,
    required this.productsWithStock,
    required this.lowStockCount,
    required this.movementIn30d,
    required this.movementOut30d,
    required this.gradeBreakdown,
    required this.topProductsByStock,
    required this.recentMovements,
    required this.revenue,
    required this.ordersCount,
    required this.itemsCount,
    required this.customersCount,
    required this.vendorsCount,
    required this.purchasesCount,
    required this.purchasesAmount,
    required this.vendorReceivedQty,
    required this.invoiceSummary,
    required this.billSummary,
    required this.approvalsPendingCount,
  });

  factory InventoryDashboardStats.fromJson(Map<String, dynamic> json) {
    return InventoryDashboardStats(
      lotsCount: _int(json['lotsCount']),
      stockCount: _int(json['stockCount']),
      productsWithStock: _int(json['productsWithStock']),
      lowStockCount: _int(json['lowStockCount']),
      movementIn30d: _int(json['movementIn30d']),
      movementOut30d: _int(json['movementOut30d']),
      gradeBreakdown: (json['gradeBreakdown'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(
                k,
                GradeBreakdownEntry.fromJson(v as Map<String, dynamic>),
              )),
      topProductsByStock: (json['topProductsByStock'] as List? ?? [])
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentMovements: (json['recentMovements'] as List? ?? [])
          .map((e) => RecentMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
      revenue: _double(json['revenue']),
      ordersCount: _int(json['ordersCount']),
      itemsCount: _int(json['itemsCount']),
      customersCount: _int(json['customersCount']),
      vendorsCount: _int(json['vendorsCount']),
      purchasesCount: _int(json['purchasesCount']),
      purchasesAmount: _double(json['purchasesAmount']),
      vendorReceivedQty: _int(json['vendorReceivedQty']),
      invoiceSummary: SummaryCount.fromJson(
        json['invoiceSummary'] as Map<String, dynamic>? ?? const {},
      ),
      billSummary: SummaryCount.fromJson(
        json['billSummary'] as Map<String, dynamic>? ?? const {},
      ),
      approvalsPendingCount: _int(json['approvalsPendingCount']),
    );
  }
}

class GradeBreakdownEntry {
  final int processed;
  final int available;
  final int sold;

  GradeBreakdownEntry({
    required this.processed,
    required this.available,
    required this.sold,
  });

  factory GradeBreakdownEntry.fromJson(Map<String, dynamic> json) {
    final processed = _int(json['processed']);
    final available = _int(json['available']);
    final sold = json['sold'] != null
        ? _int(json['sold'])
        : (processed - available < 0 ? 0 : processed - available);
    return GradeBreakdownEntry(
      processed: processed,
      available: available,
      sold: sold,
    );
  }
}

class TopProduct {
  final int id;
  final String name;
  final String sku;
  final String? productCode;
  final int currentStock;
  final int? reorderLevel;
  final String unit;
  final bool lowStock;

  TopProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.productCode,
    required this.currentStock,
    required this.reorderLevel,
    required this.unit,
    required this.lowStock,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      productCode: json['productCode']?.toString(),
      currentStock: _int(json['currentStock']),
      reorderLevel: json['reorderLevel'] == null ? null : _int(json['reorderLevel']),
      unit: json['unit']?.toString() ?? '',
      lowStock: json['lowStock'] == true,
    );
  }
}

class RecentMovement {
  final int id;
  final String type;
  final int quantity;
  final String direction; // "IN" | "OUT"
  final int absQty;
  final String? itemName;
  final String? itemSku;
  final DateTime? createdAt;

  RecentMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.direction,
    required this.absQty,
    required this.itemName,
    required this.itemSku,
    required this.createdAt,
  });

  factory RecentMovement.fromJson(Map<String, dynamic> json) {
    return RecentMovement(
      id: _int(json['id']),
      type: json['type']?.toString() ?? '',
      quantity: _int(json['quantity']),
      direction: json['direction']?.toString() ?? '',
      absQty: _int(json['absQty']),
      itemName: json['itemName']?.toString(),
      itemSku: json['itemSku']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class SummaryCount {
  final int count;
  final double amount;

  SummaryCount({required this.count, required this.amount});

  factory SummaryCount.fromJson(Map<String, dynamic> json) {
    return SummaryCount(
      count: _int(json['count']),
      amount: _double(json['amount']),
    );
  }
}

// ───────── shared tolerant parsers ─────────
int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse('$v') ?? 0.0;
}