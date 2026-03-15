enum UserRole {
  owner,
  manager,
  chef,
  kitchen_staff,
  front_of_house;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.chef:
        return 'Chef';
      case UserRole.kitchen_staff:
        return 'Kitchen Staff';
      case UserRole.front_of_house:
        return 'Front of House';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.kitchen_staff,
    );
  }
}

class Profile {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final String businessId;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.businessId,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: UserRole.fromString(json['role'] as String),
      businessId: json['business_id'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.name,
        'business_id': businessId,
        'avatar_url': avatarUrl,
      };

  bool get isManager => role == UserRole.owner || role == UserRole.manager;
  bool get canManageRecipes =>
      role == UserRole.owner ||
      role == UserRole.manager ||
      role == UserRole.chef;
}
