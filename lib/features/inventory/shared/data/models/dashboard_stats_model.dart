class InventoryDashboardStats {
  final int lowStockCount;
  final int itemsCount;
  final int stockCount;

  InventoryDashboardStats({
    required this.lowStockCount,
    required this.itemsCount,
    required this.stockCount,
  });

  factory InventoryDashboardStats.fromJson(Map<String, dynamic> json) {
    return InventoryDashboardStats(
      lowStockCount: json['lowStockCount'] is int
          ? json['lowStockCount']
          : int.tryParse('${json['lowStockCount']}') ?? 0,
      itemsCount: json['itemsCount'] is int
          ? json['itemsCount']
          : int.tryParse('${json['itemsCount']}') ?? 0,
      stockCount: json['stockCount'] is int
          ? json['stockCount']
          : int.tryParse('${json['stockCount']}') ?? 0,
    );
  }
}