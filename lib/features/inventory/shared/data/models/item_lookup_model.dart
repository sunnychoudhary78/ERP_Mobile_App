/// Compact item row from `GET /api/lookups/items` (Section 6.1b).
class ItemLookupResult {
  final int id;
  final String name;
  final String sku;
  final String? productCode;
  final String? brandName;
  final String? unit;

  ItemLookupResult({
    required this.id,
    required this.name,
    required this.sku,
    this.productCode,
    this.brandName,
    this.unit,
  });

  factory ItemLookupResult.fromJson(Map<String, dynamic> json) {
    return ItemLookupResult(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      productCode: json['productCode']?.toString(),
      brandName: json['brandName']?.toString(),
      unit: json['unit']?.toString(),
    );
  }
}