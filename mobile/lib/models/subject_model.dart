class SubjectModel {
  final String id;
  final String name;
  final String? description;
  final String? code;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubjectModel({
    required this.id,
    required this.name,
    this.description,
    this.code,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      code: json['code'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (code != null) 'code': code,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      if (name.isNotEmpty) 'name': name,
      if (description != null) 'description': description,
      if (code != null) 'code': code,
      'isActive': isActive,
    };
  }

  SubjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
