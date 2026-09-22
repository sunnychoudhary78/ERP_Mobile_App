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

class ProductCategory {
  final int id;
  final String name;
  final String? type;
  final String status;
  final String? hsnSac;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductCategory({
    required this.id,
    required this.name,
    this.type,
    required this.status,
    this.hsnSac,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      hsnSac: json['hsnSac']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static int _parseInt(dynamic value) {
    return value is int ? value : int.tryParse('$value') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}