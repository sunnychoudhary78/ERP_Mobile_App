/// lib/features/inventory/shared/data/models/cost_history_model.dart
///
/// `GET /api/items/:id/cost-history` row. The doc doesn't pin an exact
/// field-by-field shape, so this reads a few likely field-name variants
/// and keeps the raw map available via `[]` for anything else the
/// backend sends.
class CostHistoryEntry {
  final Map<String, dynamic> raw;

  CostHistoryEntry(this.raw);

  factory CostHistoryEntry.fromJson(Map<String, dynamic> json) =>
      CostHistoryEntry(json);

  num? get cost => _num(
        raw['costPrice'] ?? raw['cost'] ?? raw['newCost'] ?? raw['price'],
      );

  num? get previousCost => _num(raw['oldCost'] ?? raw['previousCost']);

  DateTime? get date {
    final v = raw['createdAt'] ??
        raw['effectiveDate'] ??
        raw['changedAt'] ??
        raw['date'];
    if (v == null) return null;
    return DateTime.tryParse('$v');
  }

  String? get note =>
      raw['note']?.toString() ??
      raw['reason']?.toString() ??
      raw['remark']?.toString();

  dynamic operator [](String key) => raw[key];

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse('$v');
  }
}