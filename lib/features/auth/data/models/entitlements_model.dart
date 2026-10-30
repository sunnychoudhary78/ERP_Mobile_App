/// Company/module entitlements returned by `GET /api/auth/me`.
///
/// Shape (doc 05 — User & Team Management):
/// ```json
/// "entitlements": {
///   "modules":  { "sales": true },
///   "features": { "tracking": true }
/// }
/// ```
///
/// Sales Tracking is shown only when `moduleSales` **and** `featureTracking`
/// are both true (plus the matching permission — see `SalesEntitlement`).
class Entitlements {
  final Map<String, bool> modules;
  final Map<String, bool> features;

  const Entitlements({
    this.modules = const {},
    this.features = const {},
  });

  static const Entitlements empty = Entitlements();

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    return Entitlements(
      modules: _boolMap(json['modules']),
      features: _boolMap(json['features']),
    );
  }

  bool get moduleSales => modules['sales'] == true;
  bool get featureTracking => features['tracking'] == true;

  static Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, v) => MapEntry(key.toString(), v == true));
  }
}
