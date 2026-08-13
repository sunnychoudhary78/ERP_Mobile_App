
class FinancialReport {
  final Map<String, dynamic> raw;

  FinancialReport(this.raw);

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(json);
  }


  num? get purchasesAmount => _num(raw['purchasesAmount']);
  num? get salesAmount => _num(raw['salesAmount']);
  num? get revenue => _num(raw['revenue']);

  dynamic operator [](String key) => raw[key];

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse('$v');
  }
}