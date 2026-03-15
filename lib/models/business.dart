class Business {
  final String id;
  final String name;
  final String? address;
  final String? registrationNumber;
  final DateTime createdAt;

  Business({
    required this.id,
    required this.name,
    this.address,
    this.registrationNumber,
    required this.createdAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      registrationNumber: json['registration_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'registration_number': registrationNumber,
      };
}
