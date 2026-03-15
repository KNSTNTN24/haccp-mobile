class Incident {
  final String id;
  final String type; // 'complaint' or 'incident'
  final String description;
  final String? actionTaken;
  final String? followUp;
  final String reportedBy;
  final String date;
  final String businessId;
  final DateTime createdAt;
  // Joined
  final String? reportedByName;

  Incident({
    required this.id,
    required this.type,
    required this.description,
    this.actionTaken,
    this.followUp,
    required this.reportedBy,
    required this.date,
    required this.businessId,
    required this.createdAt,
    this.reportedByName,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      actionTaken: json['action_taken'] as String?,
      followUp: json['follow_up'] as String?,
      reportedBy: json['reported_by'] as String,
      date: json['date'] as String,
      businessId: json['business_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reportedByName: json['profiles'] != null
          ? (json['profiles'] as Map)['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'action_taken': actionTaken,
        'follow_up': followUp,
        'reported_by': reportedBy,
        'date': date,
        'business_id': businessId,
      };
}
