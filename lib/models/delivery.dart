class Delivery {
  final String id;
  final String? supplierId;
  final String? receivedBy;
  final DateTime receivedAt;
  final double? productTemperature;
  final String? notes;
  final String businessId;
  final DateTime createdAt;
  // Joined data
  final String? supplierName;
  final String? receivedByName;
  final List<DeliveryPhoto> photos;

  Delivery({
    required this.id,
    this.supplierId,
    this.receivedBy,
    required this.receivedAt,
    this.productTemperature,
    this.notes,
    required this.businessId,
    required this.createdAt,
    this.supplierName,
    this.receivedByName,
    this.photos = const [],
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      supplierId: json['supplier_id'] as String?,
      receivedBy: json['received_by'] as String?,
      receivedAt: DateTime.parse(json['received_at'] as String),
      productTemperature: (json['product_temperature'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      businessId: json['business_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      supplierName: json['suppliers'] != null
          ? (json['suppliers'] as Map)['name'] as String?
          : null,
      receivedByName: json['profiles'] != null
          ? (json['profiles'] as Map)['full_name'] as String?
          : null,
      photos: json['delivery_photos'] != null
          ? (json['delivery_photos'] as List)
              .map((e) => DeliveryPhoto.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class DeliveryPhoto {
  final String id;
  final String deliveryId;
  final String photoUrl;
  final String? fileName;
  final DateTime createdAt;

  DeliveryPhoto({
    required this.id,
    required this.deliveryId,
    required this.photoUrl,
    this.fileName,
    required this.createdAt,
  });

  factory DeliveryPhoto.fromJson(Map<String, dynamic> json) {
    return DeliveryPhoto(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      photoUrl: json['photo_url'] as String,
      fileName: json['file_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
