import 'package:flutter/foundation.dart';
import '../models/class_model.dart';
import '../models/student_progress_model.dart';
import '../services/api_service.dart';
import '../services/teacher_service.dart';

/// Provider pour gérer les classes et élèves du teacher
class TeacherProvider with ChangeNotifier {
  final TeacherService _teacherService;
  
  // Classes
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  bool _isLoadingClasses = false;
  String? _classesError;

  // Stats
  int _totalClasses = 0;
  int _totalStudents = 0;
  bool _isLoadingStats = false;
  String? _statsError;

  // Progress
  ClassProgressStatsModel? _classProgress;
  bool _isLoadingProgress = false;
  String? _progressError;
  String _sortBy = 'best'; // 'best', 'worst', 'name'

  TeacherProvider(ApiService apiService)
      : _teacherService = TeacherService(apiService);

  // Getters pour Classes
  List<ClassModel> get classes => _classes;
  ClassModel? get selectedClass => _selectedClass;
  bool get isLoadingClasses => _isLoadingClasses;
  String? get classesError => _classesError;

  // Getters pour Stats
  int get totalClasses => _totalClasses;
  int get totalStudents => _totalStudents;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  // Getters pour Progress
  ClassProgressStatsModel? get classProgress => _classProgress;
  bool get isLoadingProgress => _isLoadingProgress;
  String? get progressError => _progressError;
  String get sortBy => _sortBy;

  /// Students triés selon le critère sélectionné
  List<StudentProgressModel> get sortedStudents {
    if (_classProgress == null) return [];

    final students = List<StudentProgressModel>.from(_classProgress!.students);

    switch (_sortBy) {
      case 'best':
        students.sort((a, b) => b.avgScore.compareTo(a.avgScore));
        break;
      case 'worst':
        students.sort((a, b) => a.avgScore.compareTo(b.avgScore));
        break;
      case 'name':
        students.sort((a, b) => a.kidName.compareTo(b.kidName));
        break;
    }

    return students;
  }

  /// Charge les statistiques (KPIs)
  Future<void> loadStats() async {
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      // Charger les classes pour calculer les stats
      await loadClasses();
      
      _totalClasses = _classes.length;
      _totalStudents = _classes.fold<int>(
        0,
        (sum, classModel) => sum + (classModel.members?.length ?? 0),
      );
      
      _isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [TeacherProvider] Error loading stats: $e');
      _statsError = e.toString();
      _isLoadingStats = false;
      _totalClasses = 0;
      _totalStudents = 0;
      notifyListeners();
    }
  }

  /// Charge toutes les classes du teacher
  Future<void> loadClasses() async {
    _isLoadingClasses = true;
    _classesError = null;
    notifyListeners();

    try {
      final classesData = await _teacherService.getClasses();
      
      _classes = classesData
          .map((data) => ClassModel.fromJson(data))
          .toList();
      
      _isLoadingClasses = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [TeacherProvider] Error loading classes: $e');
      _classesError = e.toString();
      _isLoadingClasses = false;
      _classes = [];
      notifyListeners();
      rethrow;
    }
  }

  /// Charge les détails d'une classe (avec membres)
  Future<void> loadClassDetails(String classId) async {
    _isLoadingClasses = true;
    _classesError = null;
    notifyListeners();

    try {
      final classData = await _teacherService.getClassDetails(classId);
      _selectedClass = ClassModel.fromJson(classData);
      
      // Mettre à jour dans la liste aussi
      final index = _classes.indexWhere((c) => c.id == classId);
      if (index != -1) {
        _classes[index] = _selectedClass!;
      }
      
      _isLoadingClasses = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [TeacherProvider] Error loading class details: $e');
      _classesError = e.toString();
      _isLoadingClasses = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Crée une nouvelle classe
  Future<ClassModel> createClass(ClassModel classModel) async {
    _isLoadingClasses = true;
    _classesError = null;
    notifyListeners();

    try {
      final data = await _teacherService.createClass(classModel.toJson());
      final newClass = ClassModel.fromJson(data);
      
      _classes.insert(0, newClass);
      _totalClasses = _classes.length;
      
      _isLoadingClasses = false;
      notifyListeners();
      return newClass;
    } catch (e) {
      debugPrint('❌ [TeacherProvider] Error creating class: $e');
      _classesError = e.toString();
      _isLoadingClasses = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Ajoute un élève à une classe
  Future<void> addStudentToClass(String classId, String kidId) async {
    _isLoadingClasses = true;
    _classesError = null;
    notifyListeners();

    try {
      await _teacherService.addStudentToClass(classId, kidId);
      
      // Recharger les détails de la classe
      await loadClassDetails(classId);
      
      // Mettre à jour les stats
      await loadStats();
      
      _isLoadingClasses = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [TeacherProvider] Error adding student: $e');
      _classesError = e.toString();
      _isLoadingClasses = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime un élève d'une classe
  Future<void> removeStudentFromClass(String classId, String kidId) async {
    _isLoadingClasses = true;
    _classesError = null;
    notifyListeners();

    try {
      await _teacherService.removeStudentFromClass(classId, kidId);
      
      // Recharger les détails de la classe
      await loadClassDetails(classId);
      
      // Mettre à jour les stats
      await loadStats();
      
      _isLoadingClasses = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [TeacherProvider] Error removing student: $e');
      _classesError = e.toString();
      _isLoadingClasses = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Charge le suivi de progression pour une classe et une matière
  Future<void> loadClassSubjectProgress(
    String classId,
    String subjectId,
  ) async {
    _isLoadingProgress = true;
    _progressError = null;
    notifyListeners();

    try {
      final data = await _teacherService.getClassSubjectProgress(
        classId,
        subjectId,
      );
      
      _classProgress = ClassProgressStatsModel.fromJson(data);
      
      _isLoadingProgress = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [TeacherProvider] Error loading progress: $e');
      _progressError = e.toString();
      _isLoadingProgress = false;
      _classProgress = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Change le critère de tri
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  /// Réinitialise l'erreur
  void clearError() {
    _classesError = null;
    _statsError = null;
    _progressError = null;
    notifyListeners();
  }
}
