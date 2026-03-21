class StaffCheckin {
  final String id;
  final String userId;
  final String businessId;
  final DateTime checkedInAt;
  final DateTime? checkedOutAt;
  final String date;
  final String? mood;
  // Joined from profiles
  final String? fullName;
  final String? avatarUrl;
  final String? role;

  StaffCheckin({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.checkedInAt,
    this.checkedOutAt,
    required this.date,
    this.mood,
    this.fullName,
    this.avatarUrl,
    this.role,
  });

  bool get isCheckedIn => checkedOutAt == null;

  factory StaffCheckin.fromJson(Map<String, dynamic> json) {
    return StaffCheckin(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String),
      checkedOutAt: json['checked_out_at'] != null
          ? DateTime.parse(json['checked_out_at'] as String)
          : null,
      date: json['date'] as String,
      mood: json['mood'] as String?,
      fullName: json['profiles'] != null
          ? (json['profiles'] as Map)['full_name'] as String?
          : null,
      avatarUrl: json['profiles'] != null
          ? (json['profiles'] as Map)['avatar_url'] as String?
          : null,
      role: json['profiles'] != null
          ? (json['profiles'] as Map)['role'] as String?
          : null,
    );
  }
}
