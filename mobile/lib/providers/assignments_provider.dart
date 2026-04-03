import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/assignment_model.dart';
import '../services/api_service.dart';
import '../services/assignments_service.dart';

/// Provider pour gérer les assignments (teacher et kid)
class AssignmentsProvider with ChangeNotifier {
  final AssignmentsService _assignmentsService;

  // Teacher assignments
  List<AssignmentModel> _assignments = [];
  bool _isLoadingAssignments = false;
  String? _assignmentsError;

  // Submissions
  List<AssignmentSubmissionModel> _submissions = [];
  bool _isLoadingSubmissions = false;
  String? _submissionsError;

  // Kid assignments
  List<AssignmentModel> _kidAssignments = [];
  bool _isLoadingKidAssignments = false;
  String? _kidAssignmentsError;

  AssignmentsProvider(ApiService apiService)
      : _assignmentsService = AssignmentsService(apiService);

  // Getters pour Teacher assignments
  List<AssignmentModel> get assignments => _assignments;
  bool get isLoadingAssignments => _isLoadingAssignments;
  String? get assignmentsError => _assignmentsError;

  // Getters pour Submissions
  List<AssignmentSubmissionModel> get submissions => _submissions;
  bool get isLoadingSubmissions => _isLoadingSubmissions;
  String? get submissionsError => _submissionsError;

  // Getters pour Kid assignments
  List<AssignmentModel> get kidAssignments => _kidAssignments;
  bool get isLoadingKidAssignments => _isLoadingKidAssignments;
  String? get kidAssignmentsError => _kidAssignmentsError;

  /// Charge les assignments d'une classe (teacher)
  Future<void> loadAssignmentsByClass(String classId) async {
    _isLoadingAssignments = true;
    _assignmentsError = null;
    notifyListeners();

    try {
      final data = await _assignmentsService.getAssignmentsByClass(classId);
      _assignments = data
          .map((json) => AssignmentModel.fromJson(json))
          .toList();
      _assignmentsError = null;
    } catch (e) {
      _assignmentsError = e.toString();
      _assignments = [];
    } finally {
      _isLoadingAssignments = false;
      notifyListeners();
    }
  }

  /// Crée un nouvel assignment (teacher), avec pièces jointes optionnelles.
  Future<bool> createAssignment(
    Map<String, dynamic> data, {
    List<PlatformFile> files = const [],
  }) async {
    _assignmentsError = null;
    notifyListeners();

    try {
      final result = await _assignmentsService.createAssignment(
        data,
        files: files,
      );
      final newAssignment = AssignmentModel.fromJson(result);
      _assignments.add(newAssignment);
      _assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      _assignmentsError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _assignmentsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Charge les soumissions d'un assignment (teacher)
  Future<void> loadAssignmentSubmissions(String assignmentId) async {
    _isLoadingSubmissions = true;
    _submissionsError = null;
    notifyListeners();

    try {
      final data = await _assignmentsService.getAssignmentSubmissions(assignmentId);
      _submissions = data
          .map((json) => AssignmentSubmissionModel.fromJson(json))
          .toList();
      _submissionsError = null;
    } catch (e) {
      _submissionsError = e.toString();
      _submissions = [];
    } finally {
      _isLoadingSubmissions = false;
      notifyListeners();
    }
  }

  /// Charge les assignments d'un kid
  Future<void> loadKidAssignments() async {
    _isLoadingKidAssignments = true;
    _kidAssignmentsError = null;
    notifyListeners();

    try {
      final data = await _assignmentsService.getKidAssignments();
      _kidAssignments = data
          .map((json) => AssignmentModel.fromJson(json))
          .toList();
      _kidAssignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      _kidAssignmentsError = null;
    } catch (e) {
      _kidAssignmentsError = e.toString();
      _kidAssignments = [];
    } finally {
      _isLoadingKidAssignments = false;
      notifyListeners();
    }
  }

  /// Démarre un assignment (kid)
  Future<bool> startAssignment(String assignmentId) async {
    _kidAssignmentsError = null;
    notifyListeners();

    try {
      await _assignmentsService.startAssignment(assignmentId);
      // Recharger les assignments pour mettre à jour le statut
      await loadKidAssignments();
      _kidAssignmentsError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _kidAssignmentsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Soumet un assignment (kid)
  Future<bool> submitAssignment(
    String assignmentId, {
    String? quizSessionId,
    double? score,
  }) async {
    _kidAssignmentsError = null;
    notifyListeners();

    try {
      await _assignmentsService.submitAssignment(
        assignmentId,
        quizSessionId: quizSessionId,
        score: score,
      );
      // Recharger les assignments pour mettre à jour le statut
      await loadKidAssignments();
      _kidAssignmentsError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _kidAssignmentsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Efface les erreurs
  void clearError() {
    _assignmentsError = null;
    _submissionsError = null;
    _kidAssignmentsError = null;
    notifyListeners();
  }

  /// Réinitialise les assignments (teacher)
  void clearAssignments() {
    _assignments = [];
    _assignmentsError = null;
    notifyListeners();
  }

  /// Réinitialise les soumissions
  void clearSubmissions() {
    _submissions = [];
    _submissionsError = null;
    notifyListeners();
  }

  /// Réinitialise les assignments (kid)
  void clearKidAssignments() {
    _kidAssignments = [];
    _kidAssignmentsError = null;
    notifyListeners();
  }
}
