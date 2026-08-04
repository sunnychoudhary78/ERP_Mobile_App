class InventoryProductItem {
  final int id;
  final String name;
  final String sku;
  final int currentStock;
  final int reorderLevel;

  InventoryProductItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.reorderLevel,
  });

  factory InventoryProductItem.fromJson(Map<String, dynamic> json) {
    return InventoryProductItem(
      id: json['id'],
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      currentStock: json['currentStock'] ?? 0,
      reorderLevel: json['reorderLevel'] ?? 0,
    );
  }
}