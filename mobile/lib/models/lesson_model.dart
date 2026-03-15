class LessonModel {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String? content;
  final int? order;
  final String? level;
  final String? language;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LessonModel({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.content,
    this.order,
    this.level,
    this.language,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      content: json['content'],
      order: json['order'] != null ? int.tryParse(json['order'].toString()) : null,
      level: json['level'],
      language: json['language'],
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
      'subjectId': subjectId,
      'title': title,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (order != null) 'order': order,
      if (level != null) 'level': level,
      if (language != null) 'language': language,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      if (subjectId.isNotEmpty) 'subjectId': subjectId,
      if (title.isNotEmpty) 'title': title,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (order != null) 'order': order,
      if (level != null) 'level': level,
      if (language != null) 'language': language,
      'isActive': isActive,
    };
  }

  LessonModel copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    String? content,
    int? order,
    String? level,
    String? language,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      order: order ?? this.order,
      level: level ?? this.level,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
