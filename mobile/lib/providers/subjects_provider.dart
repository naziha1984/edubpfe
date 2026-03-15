import 'package:flutter/foundation.dart';
import '../models/subject_model.dart';
import '../services/api_service.dart';
import '../services/subjects_service.dart';

/// Provider pour gérer le CRUD des subjects (admin)
class SubjectsProvider with ChangeNotifier {
  final SubjectsService _subjectsService;
  
  List<SubjectModel> _subjects = [];
  bool _isLoading = false;
  String? _error;

  SubjectsProvider(ApiService apiService)
      : _subjectsService = SubjectsService(apiService);

  List<SubjectModel> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge tous les subjects
  Future<void> loadSubjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final subjectsData = await _subjectsService.getSubjects();
      
      _subjects = subjectsData
          .map((data) => SubjectModel.fromJson(data))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [SubjectsProvider] Error loading subjects: $e');
      _error = e.toString();
      _isLoading = false;
      _subjects = [];
      notifyListeners();
      rethrow;
    }
  }

  /// Crée un nouveau subject
  Future<SubjectModel> createSubject(SubjectModel subject) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _subjectsService.createSubject(subject.toJson());
      final newSubject = SubjectModel.fromJson(data);
      
      _subjects.add(newSubject);
      _subjects.sort((a, b) => a.name.compareTo(b.name));
      
      _isLoading = false;
      notifyListeners();
      return newSubject;
    } catch (e) {
      debugPrint('❌ [SubjectsProvider] Error creating subject: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Met à jour un subject
  Future<SubjectModel> updateSubject(SubjectModel subject) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _subjectsService.updateSubject(
        subject.id,
        subject.toJsonForUpdate(),
      );
      final updatedSubject = SubjectModel.fromJson(data);
      
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = updatedSubject;
        _subjects.sort((a, b) => a.name.compareTo(b.name));
      }
      
      _isLoading = false;
      notifyListeners();
      return updatedSubject;
    } catch (e) {
      debugPrint('❌ [SubjectsProvider] Error updating subject: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime un subject
  Future<void> deleteSubject(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _subjectsService.deleteSubject(id);
      
      _subjects.removeWhere((s) => s.id == id);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [SubjectsProvider] Error deleting subject: $e');
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
