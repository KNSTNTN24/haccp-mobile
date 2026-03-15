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
  yes_no;

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
    }
  }

  static ChecklistItemType fromString(String value) {
    return ChecklistItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChecklistItemType.tick,
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
  final String? notes;
  final String businessId;
  final List<ChecklistResponse>? responses;
  // Joined data
  final String? completedByName;
  final String? templateName;

  ChecklistCompletion({
    required this.id,
    required this.templateId,
    required this.completedBy,
    required this.completedAt,
    this.signedOffBy,
    this.notes,
    required this.businessId,
    this.responses,
    this.completedByName,
    this.templateName,
  });

  factory ChecklistCompletion.fromJson(Map<String, dynamic> json) {
    return ChecklistCompletion(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      completedBy: json['completed_by'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      signedOffBy: json['signed_off_by'] as String?,
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
