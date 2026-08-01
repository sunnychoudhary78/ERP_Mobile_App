class InventoryCustomer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? status;

  const InventoryCustomer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.status,
  });

  factory InventoryCustomer.fromJson(Map<String, dynamic> json) {
    return InventoryCustomer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString(),
    );
  }
}
