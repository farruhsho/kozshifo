/// A supplier (mirrors backend `SupplierOut`). Plain immutable class (no
/// codegen) — only used to populate the optional supplier picker on a receipt.
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        isActive: (json['is_active'] as bool?) ?? true,
      );
}
