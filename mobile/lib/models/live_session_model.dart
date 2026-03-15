class LiveSessionModel {
  final String id;
  final String classId;
  final Map<String, dynamic>? classData; // Populated class data (for kid view)
  final String teacherId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final String meetingUrl;
  final LiveSessionStatus status;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LiveSessionModel({
    required this.id,
    required this.classId,
    this.classData,
    required this.teacherId,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.meetingUrl,
    required this.status,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    return LiveSessionModel(
      id: json['id']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      classData: json['class'] is Map
          ? Map<String, dynamic>.from(json['class'])
          : null,
      teacherId: json['teacherId']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : DateTime.now(),
      meetingUrl: json['meetingUrl'] ?? '',
      status: LiveSessionStatus.fromString(json['status'] ?? 'SCHEDULED'),
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
      'classId': classId,
      'title': title,
      if (description != null) 'description': description,
      'scheduledAt': scheduledAt.toIso8601String(),
      'meetingUrl': meetingUrl,
    };
  }

  LiveSessionModel copyWith({
    String? id,
    String? classId,
    Map<String, dynamic>? classData,
    String? teacherId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    String? meetingUrl,
    LiveSessionStatus? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveSessionModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      classData: classData ?? this.classData,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get className {
    if (classData != null) {
      return classData!['name'] ?? 'Unknown Class';
    }
    return 'Unknown Class';
  }

  bool get isUpcoming {
    return scheduledAt.isAfter(DateTime.now()) &&
        status == LiveSessionStatus.scheduled;
  }

  bool get isLive {
    return status == LiveSessionStatus.live;
  }

  bool get isPast {
    return scheduledAt.isBefore(DateTime.now()) ||
        status == LiveSessionStatus.completed;
  }

  Duration get timeUntilStart {
    return scheduledAt.difference(DateTime.now());
  }

  String get timeUntilStartFormatted {
    final duration = timeUntilStart;
    if (duration.isNegative) {
      return 'En cours';
    }
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}j ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}

enum LiveSessionStatus {
  scheduled,
  live,
  completed,
  cancelled;

  static LiveSessionStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return LiveSessionStatus.scheduled;
      case 'LIVE':
        return LiveSessionStatus.live;
      case 'COMPLETED':
        return LiveSessionStatus.completed;
      case 'CANCELLED':
        return LiveSessionStatus.cancelled;
      default:
        return LiveSessionStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case LiveSessionStatus.scheduled:
        return 'Programmée';
      case LiveSessionStatus.live:
        return 'En direct';
      case LiveSessionStatus.completed:
        return 'Terminée';
      case LiveSessionStatus.cancelled:
        return 'Annulée';
    }
  }
}
