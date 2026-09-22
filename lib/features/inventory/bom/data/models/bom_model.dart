import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';

class BomMaterial {
  final int itemId;
  final ItemLookupResult? item;
  final num quantity;
  final String? uom;
  final num scrapPct;
  final num consumptionFactor;
  final String? componentType;

  const BomMaterial({
    required this.itemId,
    this.item,
    required this.quantity,
    this.uom,
    this.scrapPct = 0,
    this.consumptionFactor = 1,
    this.componentType,
  });

  factory BomMaterial.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];
    return BomMaterial(
      itemId: _toInt(json['itemId'] ?? (rawItem is Map ? rawItem['id'] : null)),
      item: rawItem is Map
          ? ItemLookupResult.fromJson(Map<String, dynamic>.from(rawItem))
          : null,
      quantity: _toNum(json['quantity']),
      uom: json['uom']?.toString(),
      scrapPct: _toNum(json['scrapPct']),
      consumptionFactor: _toNum(json['consumptionFactor'], fallback: 1),
      componentType: json['componentType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
      if (uom != null && uom!.isNotEmpty) 'uom': uom,
      'scrapPct': scrapPct,
      'consumptionFactor': consumptionFactor,
      if (componentType != null && componentType!.isNotEmpty)
        'componentType': componentType,
    };
  }
}

class BillOfMaterials {
  final int id;
  final int itemId;
  final ItemLookupResult? item;
  final String? description;
  final List<BomMaterial> materials;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BillOfMaterials({
    required this.id,
    required this.itemId,
    this.item,
    this.description,
    this.materials = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory BillOfMaterials.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];
    final rawMaterials = json['materials'];
    return BillOfMaterials(
      id: _toInt(json['id']),
      itemId: _toInt(json['itemId'] ?? (rawItem is Map ? rawItem['id'] : null)),
      item: rawItem is Map
          ? ItemLookupResult.fromJson(Map<String, dynamic>.from(rawItem))
          : null,
      description: json['description']?.toString(),
      materials: rawMaterials is List
          ? rawMaterials
                .whereType<Map>()
                .map(
                  (value) =>
                      BomMaterial.fromJson(Map<String, dynamic>.from(value)),
                )
                .toList()
          : const [],
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }
}

int _toInt(dynamic value) {
  return value is int ? value : int.tryParse('$value') ?? 0;
}

num _toNum(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  return num.tryParse('$value') ?? fallback;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
 