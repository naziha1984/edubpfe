import 'package:flutter/material.dart';

class StudentProgressModel {
  final String kidId;
  final String kidName;
  final double avgScore;
  final DateTime? lastActivity;
  final double completionRate;
  final int totalLessons;
  final int completedLessons;

  StudentProgressModel({
    required this.kidId,
    required this.kidName,
    required this.avgScore,
    this.lastActivity,
    required this.completionRate,
    required this.totalLessons,
    required this.completedLessons,
  });

  factory StudentProgressModel.fromJson(Map<String, dynamic> json) {
    return StudentProgressModel(
      kidId: json['kidId']?.toString() ?? '',
      kidName: json['kidName'] ?? '',
      avgScore: (json['avgScore'] ?? 0).toDouble(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
    );
  }

  String get level {
    if (avgScore >= 90) return 'Excellent';
    if (avgScore >= 75) return 'Good';
    if (avgScore >= 60) return 'Average';
    return 'Needs Improvement';
  }

  Color get levelColor {
    if (avgScore >= 90) return Colors.green;
    if (avgScore >= 75) return Colors.blue;
    if (avgScore >= 60) return Colors.orange;
    return Colors.red;
  }
}

class ClassProgressStatsModel {
  final String classId;
  final String subjectId;
  final List<StudentProgressModel> students;
  final OverallStatsModel overallStats;

  ClassProgressStatsModel({
    required this.classId,
    required this.subjectId,
    required this.students,
    required this.overallStats,
  });

  factory ClassProgressStatsModel.fromJson(Map<String, dynamic> json) {
    return ClassProgressStatsModel(
      classId: json['classId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      students: (json['kids'] as List<dynamic>?)
              ?.map((s) => StudentProgressModel.fromJson(s))
              .toList() ??
          [],
      overallStats: OverallStatsModel.fromJson(
        json['overallStats'] ?? {},
      ),
    );
  }
}

class OverallStatsModel {
  final int totalKids;
  final double averageScore;
  final double overallCompletionRate;

  OverallStatsModel({
    required this.totalKids,
    required this.averageScore,
    required this.overallCompletionRate,
  });

  factory OverallStatsModel.fromJson(Map<String, dynamic> json) {
    return OverallStatsModel(
      totalKids: json['totalKids'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      overallCompletionRate: (json['overallCompletionRate'] ?? 0).toDouble(),
    );
  }
}
