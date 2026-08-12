class WarehouseStockRow {
  final int id;
  final int itemId;
  final String itemName;
  final String itemSku;
  final int itemCurrentStock; // company total — NOT warehouse qty
  final int warehouseId;
  final String warehouseName;
  final int quantity; // warehouse-specific qty — use THIS

  WarehouseStockRow({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemSku,
    required this.itemCurrentStock,
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
  });

  factory WarehouseStockRow.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>? ?? {};
    final warehouse = json['warehouse'] as Map<String, dynamic>? ?? {};
    return WarehouseStockRow(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      itemId: json['itemId'] is int
          ? json['itemId']
          : int.tryParse('${json['itemId']}') ?? 0,
      itemName: item['name']?.toString() ?? '',
      itemSku: item['sku']?.toString() ?? '',
      itemCurrentStock: item['currentStock'] is int
          ? item['currentStock']
          : int.tryParse('${item['currentStock']}') ?? 0,
      warehouseId: json['warehouseId'] is int
          ? json['warehouseId']
          : int.tryParse('${json['warehouseId']}') ?? 0,
      warehouseName: warehouse['name']?.toString() ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 0,
    );
  }
}