class DiaryEntry {
  final String id;
  final String date;
  final String businessId;
  final String? signedBy;
  final String? notes;
  final bool openingDone;
  final bool closingDone;
  final DateTime createdAt;
  // Joined
  final String? signedByName;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.businessId,
    this.signedBy,
    this.notes,
    this.openingDone = false,
    this.closingDone = false,
    required this.createdAt,
    this.signedByName,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      businessId: json['business_id'] as String,
      signedBy: json['signed_by'] as String?,
      notes: json['notes'] as String?,
      openingDone: json['opening_done'] as bool? ?? false,
      closingDone: json['closing_done'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      signedByName: json['profiles'] != null
          ? (json['profiles'] as Map)['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'business_id': businessId,
        'signed_by': signedBy,
        'notes': notes,
        'opening_done': openingDone,
        'closing_done': closingDone,
      };
}
