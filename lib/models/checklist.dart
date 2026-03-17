/// Returns the start of the current period for the given frequency.
/// Used to check if a checklist has already been completed in the current period.
DateTime getPeriodStart(ChecklistFrequency frequency) {
  final now = DateTime.now();
  switch (frequency) {
    case ChecklistFrequency.daily:
      return DateTime(now.year, now.month, now.day);
    case ChecklistFrequency.weekly:
      // Monday of the current week
      final weekday = now.weekday; // 1=Mon, 7=Sun
      final monday = now.subtract(Duration(days: weekday - 1));
      return DateTime(monday.year, monday.month, monday.day);
    case ChecklistFrequency.monthly:
      return DateTime(now.year, now.month, 1);
    case ChecklistFrequency.four_weekly:
      // 28-day cycles from epoch 2024-01-01
      final epoch = DateTime(2024, 1, 1);
      final daysSinceEpoch = now.difference(epoch).inDays;
      final cycleStart = (daysSinceEpoch ~/ 28) * 28;
      return epoch.add(Duration(days: cycleStart));
    case ChecklistFrequency.custom:
      // No restriction — always allow filling
      return DateTime(1970);
  }
}

enum ChecklistFrequency {
  daily,
  weekly,
  monthly,
  four_weekly,
  custom;

  String get displayName {
    switch (this) {
      case ChecklistFrequency.daily:
        return 'Daily';
      case ChecklistFrequency.weekly:
        return 'Weekly';
      case ChecklistFrequency.monthly:
        return 'Monthly';
      case ChecklistFrequency.four_weekly:
        return '4-Weekly';
      case ChecklistFrequency.custom:
        return 'Custom';
    }
  }

  static ChecklistFrequency fromString(String value) {
    return ChecklistFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChecklistFrequency.daily,
    );
  }
}

enum ChecklistItemType {
  tick,
  temperature,
  text,
  yes_no,
  photo;

  String get displayName {
    switch (this) {
      case ChecklistItemType.tick:
        return 'Tick';
      case ChecklistItemType.temperature:
        return 'Temperature';
      case ChecklistItemType.text:
        return 'Text';
      case ChecklistItemType.yes_no:
        return 'Yes/No';
      case ChecklistItemType.photo:
        return 'Photo';
    }
  }

  static ChecklistItemType fromString(String value) {
    return ChecklistItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChecklistItemType.tick,
    );
  }
}

enum SfbbSection {
  cross_contamination,
  cleaning,
  chilling,
  cooking,
  management,
  training,
  general;

  String get displayName {
    switch (this) {
      case SfbbSection.cross_contamination:
        return 'Cross-Contamination';
      case SfbbSection.cleaning:
        return 'Cleaning';
      case SfbbSection.chilling:
        return 'Chilling';
      case SfbbSection.cooking:
        return 'Cooking';
      case SfbbSection.management:
        return 'Management';
      case SfbbSection.training:
        return 'Training';
      case SfbbSection.general:
        return 'General';
    }
  }

  static SfbbSection fromString(String? value) {
    if (value == null) return SfbbSection.general;
    return SfbbSection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SfbbSection.general,
    );
  }
}

class ChecklistTemplate {
  final String id;
  final String name;
  final String? description;
  final ChecklistFrequency frequency;
  final List<String> assignedRoles;
  final String businessId;
  final String? sfbbSection;
  final bool isDefault;
  final bool active;
  final DateTime createdAt;
  final List<ChecklistTemplateItem>? items;
  final String? supervisorRole;

  ChecklistTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.frequency,
    required this.assignedRoles,
    required this.businessId,
    this.sfbbSection,
    this.isDefault = false,
    this.active = true,
    required this.createdAt,
    this.items,
    this.supervisorRole,
  });

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      frequency: ChecklistFrequency.fromString(json['frequency'] as String),
      assignedRoles: List<String>.from(json['assigned_roles'] ?? []),
      businessId: json['business_id'] as String,
      sfbbSection: json['sfbb_section'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: json['checklist_template_items'] != null
          ? (json['checklist_template_items'] as List)
              .map((e) => ChecklistTemplateItem.fromJson(e))
              .toList()
          : null,
      supervisorRole: json['supervisor_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'frequency': frequency.name,
        'assigned_roles': assignedRoles,
        'business_id': businessId,
        'sfbb_section': sfbbSection,
        'is_default': isDefault,
        'active': active,
        'supervisor_role': supervisorRole,
      };
}

class ChecklistTemplateItem {
  final String id;
  final String templateId;
  final String name;
  final String? description;
  final ChecklistItemType itemType;
  final bool required;
  final int sortOrder;
  final String? sfbbReference;
  final double? minValue;
  final double? maxValue;
  final String? unit;

  ChecklistTemplateItem({
    required this.id,
    required this.templateId,
    required this.name,
    this.description,
    required this.itemType,
    this.required = true,
    this.sortOrder = 0,
    this.sfbbReference,
    this.minValue,
    this.maxValue,
    this.unit,
  });

  factory ChecklistTemplateItem.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplateItem(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      itemType: ChecklistItemType.fromString(json['item_type'] as String),
      required: json['required'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      sfbbReference: json['sfbb_reference'] as String?,
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'template_id': templateId,
        'name': name,
        'description': description,
        'item_type': itemType.name,
        'required': required,
        'sort_order': sortOrder,
        'sfbb_reference': sfbbReference,
        'min_value': minValue,
        'max_value': maxValue,
        'unit': unit,
      };
}

class ChecklistCompletion {
  final String id;
  final String templateId;
  final String completedBy;
  final DateTime completedAt;
  final String? signedOffBy;
  final DateTime? signedOffAt;
  final String? notes;
  final String businessId;
  final List<ChecklistResponse>? responses;
  // Joined data
  final String? completedByName;
  final String? templateName;
  final String? signedOffByName;
  final String? templateSupervisorRole;

  ChecklistCompletion({
    required this.id,
    required this.templateId,
    required this.completedBy,
    required this.completedAt,
    this.signedOffBy,
    this.signedOffAt,
    this.notes,
    required this.businessId,
    this.responses,
    this.completedByName,
    this.templateName,
    this.signedOffByName,
    this.templateSupervisorRole,
  });

  bool get isSignedOff => signedOffBy != null && signedOffAt != null;

  /// Returns display status considering supervisor role
  String get displayStatus {
    if (templateSupervisorRole == null || templateSupervisorRole!.isEmpty) {
      return 'Completed';
    }
    if (isSignedOff) return 'Signed Off';
    return 'Awaiting Sign-off';
  }

  factory ChecklistCompletion.fromJson(Map<String, dynamic> json) {
    return ChecklistCompletion(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      completedBy: json['completed_by'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      signedOffBy: json['signed_off_by'] as String?,
      signedOffAt: json['signed_off_at'] != null
          ? DateTime.parse(json['signed_off_at'] as String)
          : null,
      notes: json['notes'] as String?,
      businessId: json['business_id'] as String,
      responses: json['checklist_responses'] != null
          ? (json['checklist_responses'] as List)
              .map((e) => ChecklistResponse.fromJson(e))
              .toList()
          : null,
      completedByName: json['profiles'] != null
          ? (json['profiles'] as Map)['full_name'] as String?
          : null,
      templateName: json['checklist_templates'] != null
          ? (json['checklist_templates'] as Map)['name'] as String?
          : null,
      templateSupervisorRole: json['checklist_templates'] != null
          ? (json['checklist_templates'] as Map)['supervisor_role'] as String?
          : null,
      signedOffByName: json['signer'] != null
          ? (json['signer'] as Map)['full_name'] as String?
          : null,
    );
  }
}

class ChecklistResponse {
  final String id;
  final String completionId;
  final String itemId;
  final String value;
  final String? notes;
  final bool flagged;

  ChecklistResponse({
    required this.id,
    required this.completionId,
    required this.itemId,
    required this.value,
    this.notes,
    this.flagged = false,
  });

  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistResponse(
      id: json['id'] as String,
      completionId: json['completion_id'] as String,
      itemId: json['item_id'] as String,
      value: json['value'] as String,
      notes: json['notes'] as String?,
      flagged: json['flagged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'completion_id': completionId,
        'item_id': itemId,
        'value': value,
        'notes': notes,
        'flagged': flagged,
      };
}
