class Supplier {
  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? address;
  final String? goodsSupplied;
  final List<String> deliveryDays;
  final String businessId;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.address,
    this.goodsSupplied,
    this.deliveryDays = const [],
    required this.businessId,
    required this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String,
      contactName: json['contact_name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      goodsSupplied: json['goods_supplied'] as String?,
      deliveryDays: List<String>.from(json['delivery_days'] ?? []),
      businessId: json['business_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'address': address,
        'goods_supplied': goodsSupplied,
        'delivery_days': deliveryDays,
        'business_id': businessId,
      };
}
