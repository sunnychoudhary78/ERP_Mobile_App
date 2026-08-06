class InventoryProductItem {
  final int id;
  final String name;
  final String sku;
  final int currentStock;
  final int reorderLevel;

  // Fields used to auto-fill a quote line item when this product is
  // picked — matched against the real /items response.
  final String productCode; // e.g. "PRD-00006" -> used as Article No.
  final String hsn; // hsnSac
  final String unit;
  final String type; // productType, e.g. "SERVICE"
  final double mrp;
  final double b2bPrice;
  final double sellingPrice;
  final double costPrice;

  InventoryProductItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.reorderLevel,
    this.productCode = '',
    this.hsn = '',
    this.unit = '',
    this.type = '',
    this.mrp = 0,
    this.b2bPrice = 0,
    this.sellingPrice = 0,
    this.costPrice = 0,
  });

  /// Article No. shown on the quote line — falls back to SKU if the
  /// product has no productCode.
  String get articleNo => productCode.isNotEmpty ? productCode : sku;

  /// The rate to pre-fill on a quote line. sellingPrice is the "real"
  /// price when set; otherwise fall back to b2bPrice, then MRP.
  /// Adjust this priority if your pricing rules differ.
  double get rate {
    if (sellingPrice > 0) return sellingPrice;
    if (b2bPrice > 0) return b2bPrice;
    if (mrp > 0) return mrp;
    return costPrice;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory InventoryProductItem.fromJson(Map<String, dynamic> json) {
    // hsnSac can also live under the nested "category" object — fall
    // back to that if it's missing on the item itself.
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : const <String, dynamic>{};

    return InventoryProductItem(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      currentStock: _toInt(json['currentStock']),
      reorderLevel: _toInt(json['reorderLevel']),
      productCode: (json['productCode'] ?? '').toString(),
      hsn: (json['hsnSac'] ?? category['hsnSac'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      type: (json['productType'] ?? '').toString(),
      mrp: _toDouble(json['mrp']),
      b2bPrice: _toDouble(json['b2bPrice']),
      sellingPrice: _toDouble(json['sellingPrice']),
      costPrice: _toDouble(json['costPrice']),
    );
  }
}