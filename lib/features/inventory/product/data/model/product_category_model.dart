/// lib/features/inventory/shared/data/models/product_category_model.dart
///
/// Row shape from `GET /api/lookups/product-categories` (doc section 3).
class ProductCategoryLite {
  final int id;
  final String name;
  final String? type;
  final String? hsnSac;

  ProductCategoryLite({
    required this.id,
    required this.name,
    this.type,
    this.hsnSac,
  });

  factory ProductCategoryLite.fromJson(Map<String, dynamic> json) {
    return ProductCategoryLite(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      hsnSac: json['hsnSac']?.toString(),
    );
  }
}