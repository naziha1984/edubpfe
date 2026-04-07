import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/lesson_model.dart';
import '../services/api_service.dart';
import '../services/lessons_service.dart';

/// Provider pour gérer le CRUD des lessons (admin)
class LessonsProvider with ChangeNotifier {
  final LessonsService _lessonsService;
  
  List<LessonModel> _lessons = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSubjectId;

  LessonsProvider(ApiService apiService)
      : _lessonsService = LessonsService(apiService);

  List<LessonModel> get lessons => _lessons;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSubjectId => _currentSubjectId;

  /// Charge les lessons d'un subject
  Future<void> loadLessonsBySubject(String subjectId) async {
    _isLoading = true;
    _error = null;
    _currentSubjectId = subjectId;
    notifyListeners();

    try {
      final lessonsData = await _lessonsService.getLessonsBySubject(subjectId);
      
      _lessons = lessonsData
          .map((data) => LessonModel.fromJson(data))
          .toList();
      
      // Trier par order si disponible, sinon par titre
      _lessons.sort((a, b) {
        if (a.order != null && b.order != null) {
          return a.order!.compareTo(b.order!);
        }
        return a.title.compareTo(b.title);
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [LessonsProvider] Error loading lessons: $e');
      _error = e.toString();
      _isLoading = false;
      _lessons = [];
      notifyListeners();
      rethrow;
    }
  }

  /// Crée une nouvelle lesson
  Future<LessonModel> createLesson(
    LessonModel lesson, {
    List<PlatformFile> files = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _lessonsService.createLesson(
        lesson.toJson(),
        files,
      );
      final newLesson = LessonModel.fromJson(data);
      
      _lessons.add(newLesson);
      _lessons.sort((a, b) {
        if (a.order != null && b.order != null) {
          return a.order!.compareTo(b.order!);
        }
        return a.title.compareTo(b.title);
      });
      
      _isLoading = false;
      notifyListeners();
      return newLesson;
    } catch (e) {
      debugPrint('❌ [LessonsProvider] Error creating lesson: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Met à jour une lesson
  Future<LessonModel> updateLesson(
    LessonModel lesson, {
    List<PlatformFile> files = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _lessonsService.updateLesson(
        lesson.id,
        lesson.toJsonForUpdate(),
        files,
      );
      final updatedLesson = LessonModel.fromJson(data);
      
      final index = _lessons.indexWhere((l) => l.id == lesson.id);
      if (index != -1) {
        _lessons[index] = updatedLesson;
        _lessons.sort((a, b) {
          if (a.order != null && b.order != null) {
            return a.order!.compareTo(b.order!);
          }
          return a.title.compareTo(b.title);
        });
      }
      
      _isLoading = false;
      notifyListeners();
      return updatedLesson;
    } catch (e) {
      debugPrint('❌ [LessonsProvider] Error updating lesson: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime une lesson
  Future<void> deleteLesson(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _lessonsService.deleteLesson(id);
      
      _lessons.removeWhere((l) => l.id == id);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [LessonsProvider] Error deleting lesson: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Réinitialise l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
