class InventoryItem {
  final int id;
  final String name;
  final String sku;
  final String? productCode;
  final String? brandName;
  final String? unit;
  final int? reorderLevel;
  final int currentStock;
  final String? status;
  final String? hsnSac;
  final num? sellingPrice;
  final int? categoryId;
  final String? categoryName;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    this.productCode,
    this.brandName,
    this.unit,
    this.reorderLevel,
    required this.currentStock,
    this.status,
    this.hsnSac,
    this.sellingPrice,
    this.categoryId,
    this.categoryName,
  });

  bool get isLowStock =>
      reorderLevel != null && currentStock <= reorderLevel!;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      productCode: json['productCode']?.toString(),
      brandName: json['brandName']?.toString(),
      unit: json['unit']?.toString(),
      reorderLevel: json['reorderLevel'] is int
          ? json['reorderLevel']
          : int.tryParse('${json['reorderLevel']}'),
      currentStock: json['currentStock'] is int
          ? json['currentStock']
          : int.tryParse('${json['currentStock']}') ?? 0,
      status: json['status']?.toString(),
      hsnSac: json['hsnSac']?.toString(),
      sellingPrice: json['sellingPrice'] is num
          ? json['sellingPrice']
          : num.tryParse('${json['sellingPrice']}'),
      categoryId: json['categoryId'] is int
          ? json['categoryId']
          : int.tryParse('${json['categoryId']}'),
      categoryName: json['category']?['name']?.toString(),
    );
  }
}

class PagedItems {
  final List<InventoryItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PagedItems({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PagedItems.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List? ?? [])
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return PagedItems(
      items: list,
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 25,
      total: pagination['total'] ?? list.length,
      totalPages: pagination['totalPages'] ?? 1,
    );
  }
}