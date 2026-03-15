class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool read;
  final String? link;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.read = false,
    this.link,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      link: json['link'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
