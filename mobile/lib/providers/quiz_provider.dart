import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class QuizProvider with ChangeNotifier {
  final ApiService _apiService;
  QuizProvider(this._apiService);

  List<dynamic> _subjects = [];
  List<dynamic> _lessons = [];
  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? _quizResult;
  bool _isLoading = false;

  List<dynamic> get subjects => _subjects;
  List<dynamic> get lessons => _lessons;
  Map<String, dynamic>? get currentSession => _currentSession;
  Map<String, dynamic>? get quizResult => _quizResult;
  bool get isLoading => _isLoading;

  Future<void> loadSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await _apiService.getSubjects();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadLessons(
    String subjectId, {
    int? schoolLevel,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _lessons = await _apiService.getLessons(
        subjectId,
        schoolLevel: schoolLevel,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<dynamic>> loadQuizQuestionsForSession(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _apiService.getQuizQuestionsForSession(sessionId);
      _isLoading = false;
      notifyListeners();
      return list;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> createSession({
    required String kidId,
    required String lessonId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSession = await _apiService.createQuizSession(
        kidId: kidId,
        lessonId: lessonId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> submitQuiz({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _quizResult = await _apiService.submitQuiz(
        sessionId: sessionId,
        answers: answers,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearSession() {
    _currentSession = null;
    _quizResult = null;
    notifyListeners();
  }
}
