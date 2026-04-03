class AssignmentAttachmentModel {
  final String originalName;
  final String mimeType;
  final int size;
  /// Chemin relatif côté API, ex. `/api/uploads/assignments/xxx.pdf`
  final String url;

  AssignmentAttachmentModel({
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.url,
  });

  factory AssignmentAttachmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachmentModel(
      originalName: json['originalName']?.toString() ?? 'fichier',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      size: json['size'] is int ? json['size'] as int : int.tryParse('${json['size']}') ?? 0,
      url: json['url']?.toString() ?? '',
    );
  }
}

class AssignmentModel {
  final String id;
  final String classId;
  final String teacherId;
  final String? lessonId;
  final Map<String, dynamic>? lesson; // Populated lesson data
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AssignmentAttachmentModel> attachments;
  final AssignmentSubmissionModel? submission; // For kid view

  AssignmentModel({
    required this.id,
    required this.classId,
    required this.teacherId,
    this.lessonId,
    this.lesson,
    required this.title,
    this.description,
    required this.dueDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.submission,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      lessonId: json['lessonId']?.toString(),
      lesson: json['lesson'] is Map
          ? Map<String, dynamic>.from(json['lesson'])
          : null,
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      attachments: json['attachments'] is List
          ? (json['attachments'] as List)
              .whereType<Map>()
              .map((e) => AssignmentAttachmentModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : [],
      submission: json['submission'] != null
          ? AssignmentSubmissionModel.fromJson(json['submission'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      if (lessonId != null) 'lessonId': lessonId,
      'title': title,
      if (description != null) 'description': description,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? classId,
    String? teacherId,
    String? lessonId,
    Map<String, dynamic>? lesson,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AssignmentAttachmentModel>? attachments,
    AssignmentSubmissionModel? submission,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      lessonId: lessonId ?? this.lessonId,
      lesson: lesson ?? this.lesson,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      submission: submission ?? this.submission,
    );
  }

  // Helper getters
  String get lessonTitle {
    if (lesson != null) {
      return lesson!['title'] ?? 'No lesson';
    }
    return 'No lesson';
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate);
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference;
  }
}

enum SubmissionStatus {
  assigned,
  inProgress,
  completed;

  static SubmissionStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return SubmissionStatus.assigned;
      case 'IN_PROGRESS':
        return SubmissionStatus.inProgress;
      case 'COMPLETED':
        return SubmissionStatus.completed;
      default:
        return SubmissionStatus.assigned;
    }
  }

  String get displayName {
    switch (this) {
      case SubmissionStatus.assigned:
        return 'Assigné';
      case SubmissionStatus.inProgress:
        return 'En cours';
      case SubmissionStatus.completed:
        return 'Terminé';
    }
  }
}

class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String kidId;
  final Map<String, dynamic>? kid; // Populated kid data
  final SubmissionStatus status;
  final String? quizSessionId;
  final double? score;
  final DateTime? submittedAt;
  final DateTime? startedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.kidId,
    this.kid,
    required this.status,
    this.quizSessionId,
    this.score,
    this.submittedAt,
    this.startedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: json['id']?.toString() ?? '',
      assignmentId: json['assignmentId']?.toString() ?? '',
      kidId: json['kidId']?.toString() ?? '',
      kid: json['kid'] is Map ? Map<String, dynamic>.from(json['kid']) : null,
      status: SubmissionStatus.fromString(json['status'] ?? 'ASSIGNED'),
      quizSessionId: json['quizSessionId']?.toString(),
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
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
