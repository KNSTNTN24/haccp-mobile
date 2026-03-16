enum DocumentCategory {
  certificate,
  license,
  policy,
  instruction,
  contract,
  inspection,
  training,
  other;

  String get label {
    switch (this) {
      case certificate:
        return 'Certificate';
      case license:
        return 'License';
      case policy:
        return 'Policy';
      case instruction:
        return 'Instruction';
      case contract:
        return 'Contract';
      case inspection:
        return 'Inspection';
      case training:
        return 'Training';
      case other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case certificate:
        return '🏆';
      case license:
        return '📋';
      case policy:
        return '📜';
      case instruction:
        return '📖';
      case contract:
        return '🤝';
      case inspection:
        return '🔍';
      case training:
        return '🎓';
      case other:
        return '📄';
    }
  }
}

enum AccessLevel {
  all,
  managersOnly,
  ownerOnly,
  custom;

  String get label {
    switch (this) {
      case all:
        return 'All staff';
      case managersOnly:
        return 'Managers & Owner';
      case ownerOnly:
        return 'Owner only';
      case custom:
        return 'Selected members';
    }
  }

  String toDbValue() {
    switch (this) {
      case all:
        return 'all';
      case managersOnly:
        return 'managers_only';
      case ownerOnly:
        return 'owner_only';
      case custom:
        return 'custom';
    }
  }

  static AccessLevel fromDbValue(String value) {
    switch (value) {
      case 'managers_only':
        return AccessLevel.managersOnly;
      case 'owner_only':
        return AccessLevel.ownerOnly;
      case 'custom':
        return AccessLevel.custom;
      default:
        return AccessLevel.all;
    }
  }
}

class Document {
  final String id;
  final String title;
  final String? description;
  final DocumentCategory category;
  final String fileUrl;
  final String fileName;
  final int? fileSize;
  final String? fileType;
  final String uploadedBy;
  final String businessId;
  final AccessLevel accessLevel;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String? uploaderName;

  Document({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.fileUrl,
    required this.fileName,
    this.fileSize,
    this.fileType,
    required this.uploadedBy,
    required this.businessId,
    required this.accessLevel,
    this.expiresAt,
    required this.createdAt,
    this.uploaderName,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: DocumentCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DocumentCategory.other,
      ),
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int?,
      fileType: json['file_type'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      businessId: json['business_id'] as String,
      accessLevel: AccessLevel.fromDbValue(json['access_level'] as String? ?? 'all'),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      uploaderName: json['profiles'] != null ? json['profiles']['full_name'] as String? : null,
    );
  }

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    return expiresAt!.difference(DateTime.now()).inDays <= 30;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileIcon {
    final type = fileType?.toLowerCase() ?? '';
    if (type.contains('pdf')) return '📕';
    if (type.contains('image') || type.contains('jpeg') || type.contains('png')) return '🖼️';
    if (type.contains('word') || type.contains('docx')) return '📘';
    if (type.contains('sheet') || type.contains('xlsx')) return '📗';
    return '📄';
  }
}

class DocumentAccess {
  final String id;
  final String documentId;
  final String profileId;
  final String grantedBy;
  final DateTime createdAt;
  final String? profileName;
  final String? profileEmail;

  DocumentAccess({
    required this.id,
    required this.documentId,
    required this.profileId,
    required this.grantedBy,
    required this.createdAt,
    this.profileName,
    this.profileEmail,
  });

  factory DocumentAccess.fromJson(Map<String, dynamic> json) {
    return DocumentAccess(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      profileId: json['profile_id'] as String,
      grantedBy: json['granted_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      profileName: json['profiles'] != null ? json['profiles']['full_name'] as String? : null,
      profileEmail: json['profiles'] != null ? json['profiles']['email'] as String? : null,
    );
  }
}
