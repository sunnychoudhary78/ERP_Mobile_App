/// Field visit as returned by the ERP Smart Visit APIs (doc 02).
///
/// Maps the `mapVisit` payload from `POST/GET /api/sales/visits` and
/// `GET /api/sales/visits/:id`.
class SalesVisit {
  final String id; // V-XXXX code
  final String? dbId; // uuid (_id)
  final String? repId;
  final String? repName;
  final String clientName;
  final String? type;
  final String location;
  final String? address;
  final String? at; // visitedAt timestamp
  final String notes;
  final double? latitude;
  final double? longitude;
  final String? contact;
  final String? purpose;
  final int? rating;
  final String? photoUrl;
  final String? followUpAt;
  final bool isNewVisit;
  final double? visitDistanceKm;
  final String? sessionId;
  final String? leadId;
  final String? customerId;

  const SalesVisit({
    required this.id,
    this.dbId,
    this.repId,
    this.repName,
    required this.clientName,
    this.type,
    required this.location,
    this.address,
    this.at,
    required this.notes,
    this.latitude,
    this.longitude,
    this.contact,
    this.purpose,
    this.rating,
    this.photoUrl,
    this.followUpAt,
    this.isNewVisit = true,
    this.visitDistanceKm,
    this.sessionId,
    this.leadId,
    this.customerId,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory SalesVisit.fromJson(Map<String, dynamic> json) {
    final lat = _toDouble(json['latitude']);
    final lng = _toDouble(json['longitude']);
    return SalesVisit(
      id: json['id']?.toString() ?? '',
      dbId: json['_id']?.toString(),
      repId: json['repId']?.toString(),
      repName: json['repName']?.toString(),
      clientName: json['clientName']?.toString() ?? '',
      type: json['type']?.toString(),
      location: json['location']?.toString() ?? '',
      address: json['address']?.toString(),
      at: (json['at'] ?? json['visitedAt'])?.toString(),
      notes: json['notes']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      contact: json['contact']?.toString(),
      purpose: json['purpose']?.toString(),
      rating: _toInt(json['rating']),
      photoUrl: json['photoUrl']?.toString(),
      followUpAt: json['followUpAt']?.toString(),
      isNewVisit: json['isNewVisit'] == null
          ? true
          : json['isNewVisit'] == true || json['isNewVisit'] == 'true',
      visitDistanceKm: _toDouble(json['visitDistanceKm']),
      sessionId: json['sessionId']?.toString(),
      leadId: json['leadId']?.toString(),
      customerId: json['customerId']?.toString(),
    );
  }

  /// The value to pass to `GET /api/sales/visits/:id` — the uuid wins when
  /// present, otherwise the `V-XXXX` code (both work on the backend).
  String get refId => (dbId != null && dbId!.isNotEmpty) ? dbId! : id;

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// A remark attached to a visit (doc 02 §Add remark).
class SalesVisitRemark {
  final String id;
  final String? userId;
  final String? userName;
  final String remark;
  final String? createdAt;

  const SalesVisitRemark({
    required this.id,
    this.userId,
    this.userName,
    required this.remark,
    this.createdAt,
  });

  factory SalesVisitRemark.fromJson(Map<String, dynamic> json) {
    return SalesVisitRemark(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
      remark: json['remark']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// `GET /api/sales/visits/:id` response — the visit plus its remark thread.
class SalesVisitDetail {
  final SalesVisit visit;
  final List<SalesVisitRemark> remarks;

  const SalesVisitDetail({required this.visit, required this.remarks});
}
