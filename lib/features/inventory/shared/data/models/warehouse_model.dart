class Warehouse {
  final int id;
  final String name;
  final String? status;
  final String? address;

  Warehouse({required this.id, required this.name, this.status, this.address});

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString(),
      address: (json['address'] ?? json['location'])?.toString(),
    );
  }
}
