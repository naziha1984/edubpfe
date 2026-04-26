import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class StudentTrackingProvider with ChangeNotifier {
  final ApiService _apiService;
  StudentTrackingProvider(this._apiService);

  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> progressHistory = [];
  Map<String, dynamic>? overview;

  Future<void> loadAll(String kidId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _apiService.getStudentNotes(kidId),
        _apiService.getStudentProgressHistory(kidId),
        _apiService.getStudentTrackingOverview(kidId),
      ]);
      notes = (results[0] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      progressHistory = (results[1] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      overview = Map<String, dynamic>.from(results[2] as Map);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote({
    required String kidId,
    String? behavior,
    String? participation,
    String? homeworkQuality,
    String? comprehension,
    String? recommendations,
  }) async {
    await _apiService.addStudentNote(
      kidId: kidId,
      behavior: behavior,
      participation: participation,
      homeworkQuality: homeworkQuality,
      comprehension: comprehension,
      recommendations: recommendations,
    );
    await loadAll(kidId);
  }

  Future<void> addProgress({
    required String kidId,
    required int progressPercent,
    int? comprehensionScore,
    int? homeworkScore,
    int? participationScore,
    String? title,
    String? note,
  }) async {
    await _apiService.addStudentProgressEntry(
      kidId: kidId,
      progressPercent: progressPercent,
      comprehensionScore: comprehensionScore,
      homeworkScore: homeworkScore,
      participationScore: participationScore,
      title: title,
      note: note,
    );
    await loadAll(kidId);
  }
}
