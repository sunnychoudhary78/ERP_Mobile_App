class Vendor {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? gstNumber;
  final String? panNumber;
  final String? tdsSectionCode;
  final String? panCardUrl;
  final String? aadharCardUrl;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic> documents;

  const Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.gstNumber,
    this.panNumber,
    this.tdsSectionCode,
    this.panCardUrl,
    this.aadharCardUrl,
    this.createdAt,
    this.updatedAt,
    this.documents = const [],
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final documents = json['documents'];
    return Vendor(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      gstNumber: _string(json['gstNumber']),
      panNumber: _string(json['panNumber']),
      tdsSectionCode: _string(json['tdsSectionCode']),
      panCardUrl: _string(json['panCardUrl']),
      aadharCardUrl: _string(json['aadharCardUrl']),
      createdAt: _string(json['createdAt']),
      updatedAt: _string(json['updatedAt']),
      documents: documents is List ? List<dynamic>.from(documents) : const [],
    );
  }

  static int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static String? _string(dynamic value) => value?.toString();
}

class PagedVendors {
  final List<Vendor> vendors;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PagedVendors({
    required this.vendors,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PagedVendors.fromJson(Map<String, dynamic> json) {
    final rawVendors = json['vendors'] ?? json['data'] ?? [];
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : <String, dynamic>{};
    final rows = rawVendors is List ? rawVendors : const [];
    final page = _int(pagination['page'], fallback: 1);
    final limit = _int(pagination['limit'], fallback: rows.length);
    final total = _int(pagination['total'], fallback: rows.length);
    final totalPages = _int(
      pagination['totalPages'],
      fallback: limit > 0 ? (total / limit).ceil() : 1,
    );

    return PagedVendors(
      vendors: rows
          .whereType<Map>()
          .map((row) => Vendor.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static int _int(dynamic value, {int fallback = 0}) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}
