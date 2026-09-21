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

  // ───────── Products-screen fields (full item object) ─────────
  final String? imageUrl;
  final String? description;
  final num? mrp;
  final num? b2bPrice;
  final num? costPrice;
  final int? openingStock;
  final String? productType; // e.g. FINISHED
  final String? sourcing; // BUY | MAKE
  final String? visibility; // PUBLIC | PRIVATE
  final int? vendorId;
  final String? vendorName;
  final List<ItemStockEntry> stocks;
  final List<Map<String, dynamic>> productDimensions;
  final num? rollLengthM;
  final num? rollWidthMm;
  final num? rollThicknessMic;

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
    this.imageUrl,
    this.description,
    this.mrp,
    this.b2bPrice,
    this.costPrice,
    this.openingStock,
    this.productType,
    this.sourcing,
    this.visibility,
    this.vendorId,
    this.vendorName,
    this.stocks = const [],
    this.productDimensions = const [],
    this.rollLengthM,
    this.rollWidthMm,
    this.rollThicknessMic,
  });

  bool get isLowStock =>
      reorderLevel != null && currentStock <= reorderLevel!;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return InventoryItem(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      productCode: json['productCode']?.toString(),
      brandName: json['brandName']?.toString(),
      unit: json['unit']?.toString(),
      reorderLevel:
          json['reorderLevel'] == null ? null : _int(json['reorderLevel']),
      currentStock: _int(json['currentStock']),
      status: json['status']?.toString(),
      hsnSac: json['hsnSac']?.toString(),
      sellingPrice: _numOrNull(json['sellingPrice']),
      categoryId:
          json['categoryId'] == null ? null : _int(json['categoryId']),
      categoryName: category?['name']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      mrp: _numOrNull(json['mrp']),
      b2bPrice: _numOrNull(json['b2bPrice']),
      costPrice: _numOrNull(json['costPrice']),
      openingStock:
          json['openingStock'] == null ? null : _int(json['openingStock']),
      productType: json['productType']?.toString(),
      sourcing: json['sourcing']?.toString(),
      visibility: json['visibility']?.toString(),
      vendorId: json['vendorId'] == null ? null : _int(json['vendorId']),
      vendorName: vendor?['name']?.toString(),
      stocks: (json['stocks'] as List? ?? [])
          .map((e) => ItemStockEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      productDimensions: (json['productDimensions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      rollLengthM: _numOrNull(json['rollLengthM']),
      rollWidthMm: _numOrNull(json['rollWidthMm']),
      rollThicknessMic: _numOrNull(json['rollThicknessMic']),
    );
  }
}

class ItemStockEntry {
  final int warehouseId;
  final String warehouseName;
  final int quantity;

  ItemStockEntry({
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
  });

  factory ItemStockEntry.fromJson(Map<String, dynamic> json) {
    return ItemStockEntry(
      warehouseId: _int(json['warehouseId']),
      warehouseName: json['warehouseName']?.toString() ?? '',
      quantity: _int(json['quantity']),
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

// ───────── shared tolerant parsers ─────────
int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

num? _numOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse('$v');
}