class StockReportRow {
  final int id;
  final String name;
  final String sku;
  final String unit;
  final int currentStock;
  final int? reorderLevel;

  StockReportRow({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.currentStock,
    required this.reorderLevel,
  });

  factory StockReportRow.fromJson(Map<String, dynamic> json) {
    return StockReportRow(
      id: json['id'] is int
          ? json['id']
          : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      currentStock: json['currentStock'] is int
          ? json['currentStock']
          : int.tryParse('${json['currentStock']}') ?? 0,
      reorderLevel: json['reorderLevel'] == null
          ? null
          : (json['reorderLevel'] is int
              ? json['reorderLevel']
              : int.tryParse('${json['reorderLevel']}')),
    );
  }
}