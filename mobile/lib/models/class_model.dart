class ClassModel {
  final String id;
  final String teacherId;
  final String name;
  final String? description;
  final String classCode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ClassMemberModel>? members;

  ClassModel({
    required this.id,
    required this.teacherId,
    required this.name,
    this.description,
    required this.classCode,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.members,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      classCode: json['classCode'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => ClassMemberModel.fromJson(m))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }

  ClassModel copyWith({
    String? id,
    String? teacherId,
    String? name,
    String? description,
    String? classCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ClassMemberModel>? members,
  }) {
    return ClassModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      description: description ?? this.description,
      classCode: classCode ?? this.classCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
    );
  }
}

class ClassMemberModel {
  final String id;
  final String kidId;
  final Map<String, dynamic>? kid; // Populated kid data
  final bool isActive;
  final DateTime? joinedAt;

  ClassMemberModel({
    required this.id,
    required this.kidId,
    this.kid,
    this.isActive = true,
    this.joinedAt,
  });

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      id: json['id']?.toString() ?? '',
      kidId: json['kidId']?.toString() ?? '',
      kid: json['kid'] is Map ? Map<String, dynamic>.from(json['kid']) : null,
      isActive: json['isActive'] ?? true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : null,
    );
  }

  String get kidName {
    if (kid != null) {
      final firstName = kid!['firstName'] ?? '';
      final lastName = kid!['lastName'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return 'Unknown';
  }
}
