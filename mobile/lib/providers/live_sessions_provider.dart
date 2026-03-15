import 'package:flutter/foundation.dart';
import '../models/live_session_model.dart';
import '../services/api_service.dart';
import '../services/live_sessions_service.dart';

/// Provider pour gérer les live sessions (teacher et kid)
class LiveSessionsProvider with ChangeNotifier {
  final LiveSessionsService _liveSessionsService;

  // Teacher live sessions
  List<LiveSessionModel> _liveSessions = [];
  bool _isLoadingLiveSessions = false;
  String? _liveSessionsError;

  // Kid live sessions
  List<LiveSessionModel> _kidLiveSessions = [];
  bool _isLoadingKidLiveSessions = false;
  String? _kidLiveSessionsError;

  LiveSessionsProvider(ApiService apiService)
      : _liveSessionsService = LiveSessionsService(apiService);

  // Getters pour Teacher live sessions
  List<LiveSessionModel> get liveSessions => _liveSessions;
  bool get isLoadingLiveSessions => _isLoadingLiveSessions;
  String? get liveSessionsError => _liveSessionsError;

  // Getters pour Kid live sessions
  List<LiveSessionModel> get kidLiveSessions => _kidLiveSessions;
  bool get isLoadingKidLiveSessions => _isLoadingKidLiveSessions;
  String? get kidLiveSessionsError => _kidLiveSessionsError;

  /// Sessions à venir (pour affichage avec countdown)
  List<LiveSessionModel> get upcomingSessions {
    return _liveSessions
        .where((session) => session.isUpcoming)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Sessions en direct
  List<LiveSessionModel> get liveSessionsNow {
    return _liveSessions.where((session) => session.isLive).toList();
  }

  /// Sessions passées
  List<LiveSessionModel> get pastSessions {
    return _liveSessions
        .where((session) => session.isPast)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  /// Sessions à venir pour kids
  List<LiveSessionModel> get kidUpcomingSessions {
    return _kidLiveSessions
        .where((session) => session.isUpcoming)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Sessions en direct pour kids
  List<LiveSessionModel> get kidLiveSessionsNow {
    return _kidLiveSessions.where((session) => session.isLive).toList();
  }

  /// Charge les live sessions d'une classe (teacher)
  Future<void> loadLiveSessionsByClass(String classId) async {
    _isLoadingLiveSessions = true;
    _liveSessionsError = null;
    notifyListeners();

    try {
      final data = await _liveSessionsService.getLiveSessionsByClass(classId);
      _liveSessions = data
          .map((json) => LiveSessionModel.fromJson(json))
          .toList();
      _liveSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      _liveSessionsError = null;
    } catch (e) {
      _liveSessionsError = e.toString();
      _liveSessions = [];
    } finally {
      _isLoadingLiveSessions = false;
      notifyListeners();
    }
  }

  /// Crée une nouvelle live session (teacher)
  Future<bool> createLiveSession(String classId, Map<String, dynamic> data) async {
    _liveSessionsError = null;
    notifyListeners();

    try {
      final result = await _liveSessionsService.createLiveSession(classId, data);
      final newSession = LiveSessionModel.fromJson(result);
      _liveSessions.add(newSession);
      _liveSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      _liveSessionsError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _liveSessionsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Charge les live sessions d'un kid
  Future<void> loadKidLiveSessions() async {
    _isLoadingKidLiveSessions = true;
    _kidLiveSessionsError = null;
    notifyListeners();

    try {
      final data = await _liveSessionsService.getKidLiveSessions();
      _kidLiveSessions = data
          .map((json) => LiveSessionModel.fromJson(json))
          .toList();
      _kidLiveSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      _kidLiveSessionsError = null;
    } catch (e) {
      _kidLiveSessionsError = e.toString();
      _kidLiveSessions = [];
    } finally {
      _isLoadingKidLiveSessions = false;
      notifyListeners();
    }
  }

  /// Efface les erreurs
  void clearError() {
    _liveSessionsError = null;
    _kidLiveSessionsError = null;
    notifyListeners();
  }

  /// Réinitialise les live sessions (teacher)
  void clearLiveSessions() {
    _liveSessions = [];
    _liveSessionsError = null;
    notifyListeners();
  }

  /// Réinitialise les live sessions (kid)
  void clearKidLiveSessions() {
    _kidLiveSessions = [];
    _kidLiveSessionsError = null;
    notifyListeners();
  }
}
