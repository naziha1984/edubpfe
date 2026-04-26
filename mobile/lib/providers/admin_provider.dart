import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/admin_kid_model.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';

/// Provider pour gérer les données admin (KPIs, users, kids)
class AdminProvider with ChangeNotifier {
  final AdminService _adminService;
  
  // Indicateurs clés
  int _totalUsers = 0;
  int _totalSubjects = 0;
  int _totalLessons = 0;
  bool _isLoadingStats = false;
  String? _statsError;

  // Utilisateurs
  List<UserModel> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;
  String _searchQuery = '';
  String? _roleFilter;

  // Enfants (liste admin)
  List<AdminKidModel> _kids = [];
  bool _isLoadingKids = false;
  String? _kidsError;

  // Workflow de validation des enseignants
  List<UserModel> _pendingTeachers = [];
  bool _isLoadingPendingTeachers = false;
  String? _pendingTeachersError;
  UserModel? _teacherDetails;
  bool _isLoadingTeacherDetails = false;
  String? _teacherDetailsError;
  bool _isSubmittingTeacherDecision = false;
  String? _teacherDecisionError;

  // Vue d'ensemble du tableau de bord admin
  Map<String, dynamic>? _dashboardOverview;
  bool _isLoadingDashboardOverview = false;
  String? _dashboardOverviewError;

  // Tableau de gestion des enseignants
  List<UserModel> _teachers = [];
  bool _isLoadingTeachers = false;
  String? _teachersError;
  String _teacherSearchQuery = '';
  String? _teacherStatusFilter;

  // Tableau de modération des leçons
  List<Map<String, dynamic>> _adminLessons = [];
  bool _isLoadingAdminLessons = false;
  String? _adminLessonsError;
  String _lessonSearchQuery = '';
  String? _lessonStatusFilter;
  bool _isSubmittingLessonModeration = false;
  String? _lessonModerationError;

  // Vue d'ensemble des notifications
  Map<String, dynamic>? _notificationsOverview;
  bool _isLoadingNotificationsOverview = false;
  String? _notificationsOverviewError;

  AdminProvider(ApiService apiService)
      : _adminService = AdminService(apiService);

  // Getters pour les indicateurs clés
  int get totalUsers => _totalUsers;
  int get totalSubjects => _totalSubjects;
  int get totalLessons => _totalLessons;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  // Getters pour les utilisateurs
  List<UserModel> get users => _users;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;
  String get searchQuery => _searchQuery;
  String? get roleFilter => _roleFilter;

  // Getters pour les enfants
  List<AdminKidModel> get kids => _kids;
  bool get isLoadingKids => _isLoadingKids;
  String? get kidsError => _kidsError;

  List<UserModel> get pendingTeachers => _pendingTeachers;
  bool get isLoadingPendingTeachers => _isLoadingPendingTeachers;
  String? get pendingTeachersError => _pendingTeachersError;
  UserModel? get teacherDetails => _teacherDetails;
  bool get isLoadingTeacherDetails => _isLoadingTeacherDetails;
  String? get teacherDetailsError => _teacherDetailsError;
  bool get isSubmittingTeacherDecision => _isSubmittingTeacherDecision;
  String? get teacherDecisionError => _teacherDecisionError;
  Map<String, dynamic>? get dashboardOverview => _dashboardOverview;
  bool get isLoadingDashboardOverview => _isLoadingDashboardOverview;
  String? get dashboardOverviewError => _dashboardOverviewError;
  List<UserModel> get teachers => _teachers;
  bool get isLoadingTeachers => _isLoadingTeachers;
  String? get teachersError => _teachersError;
  String get teacherSearchQuery => _teacherSearchQuery;
  String? get teacherStatusFilter => _teacherStatusFilter;
  List<Map<String, dynamic>> get adminLessons => _adminLessons;
  bool get isLoadingAdminLessons => _isLoadingAdminLessons;
  String? get adminLessonsError => _adminLessonsError;
  String get lessonSearchQuery => _lessonSearchQuery;
  String? get lessonStatusFilter => _lessonStatusFilter;
  bool get isSubmittingLessonModeration => _isSubmittingLessonModeration;
  String? get lessonModerationError => _lessonModerationError;
  Map<String, dynamic>? get notificationsOverview => _notificationsOverview;
  bool get isLoadingNotificationsOverview => _isLoadingNotificationsOverview;
  String? get notificationsOverviewError => _notificationsOverviewError;

  /// Users filtrés selon searchQuery et roleFilter
  List<UserModel> get filteredUsers {
    var filtered = _users;

    // Filtrer par rôle
    if (_roleFilter != null && _roleFilter!.isNotEmpty) {
      filtered = filtered.where((user) => user.role == _roleFilter).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.email.toLowerCase().contains(query) ||
            user.firstName.toLowerCase().contains(query) ||
            user.lastName.toLowerCase().contains(query) ||
            user.fullName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Charge les statistiques (KPIs)
  Future<void> loadStats() async {
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      final stats = await _adminService.getStats();
      
      _totalUsers = stats['totalUsers'] ?? 0;
      _totalSubjects = stats['totalSubjects'] ?? 0;
      _totalLessons = stats['totalLessons'] ?? 0;
      
      _isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AdminProvider] Error loading stats: $e');
      _statsError = e.toString();
      _isLoadingStats = false;
      
      // Valeurs par défaut si erreur
      _totalUsers = 0;
      _totalSubjects = 0;
      _totalLessons = 0;
      
      notifyListeners();
    }
  }

  /// Charge les utilisateurs
  Future<void> loadUsers() async {
    _isLoadingUsers = true;
    _usersError = null;
    notifyListeners();

    try {
      final usersData = await _adminService.getUsers(
        role: _roleFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _users = usersData
          .map((userData) => UserModel.fromJson(userData))
          .toList();
      
      _isLoadingUsers = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AdminProvider] Error loading users: $e');
      _usersError = e.toString();
      _isLoadingUsers = false;
      _users = [];
      notifyListeners();
    }
  }

  /// Met à jour la recherche
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Met à jour le filtre de rôle
  void setRoleFilter(String? role) {
    _roleFilter = role;
    notifyListeners();
    // Recharger les utilisateurs avec le nouveau filtre
    loadUsers();
  }

  /// Réinitialise les filtres
  void resetFilters() {
    _searchQuery = '';
    _roleFilter = null;
    notifyListeners();
    loadUsers();
  }

  /// Charge la liste des enfants (admin)
  Future<void> loadKids() async {
    _isLoadingKids = true;
    _kidsError = null;
    notifyListeners();

    try {
      final data = await _adminService.getKids();
      _kids = data.map((e) => AdminKidModel.fromJson(e)).toList();
      _isLoadingKids = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AdminProvider] Error loading kids: $e');
      _kidsError = e.toString();
      _kids = [];
      _isLoadingKids = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingTeachers() async {
    _isLoadingPendingTeachers = true;
    _pendingTeachersError = null;
    notifyListeners();
    try {
      final data = await _adminService.getPendingTeachers();
      _pendingTeachers = data.map((e) => UserModel.fromJson(e)).toList();
      _isLoadingPendingTeachers = false;
      notifyListeners();
    } catch (e) {
      _pendingTeachersError = e.toString();
      _pendingTeachers = [];
      _isLoadingPendingTeachers = false;
      notifyListeners();
    }
  }

  Future<void> loadTeacherDetails(String teacherId) async {
    _isLoadingTeacherDetails = true;
    _teacherDetailsError = null;
    notifyListeners();
    try {
      final data = await _adminService.getTeacherDetails(teacherId);
      _teacherDetails = UserModel.fromJson(data);
      _isLoadingTeacherDetails = false;
      notifyListeners();
    } catch (e) {
      _teacherDetailsError = e.toString();
      _teacherDetails = null;
      _isLoadingTeacherDetails = false;
      notifyListeners();
    }
  }

  Future<bool> acceptTeacher(String teacherId) async {
    _isSubmittingTeacherDecision = true;
    _teacherDecisionError = null;
    notifyListeners();
    try {
      await _adminService.acceptTeacher(teacherId);
      _isSubmittingTeacherDecision = false;
      await loadPendingTeachers();
      await loadTeacherDetails(teacherId);
      notifyListeners();
      return true;
    } catch (e) {
      _teacherDecisionError = e.toString();
      _isSubmittingTeacherDecision = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectTeacher(String teacherId, {String? reason}) async {
    _isSubmittingTeacherDecision = true;
    _teacherDecisionError = null;
    notifyListeners();
    try {
      await _adminService.rejectTeacher(teacherId, rejectionReason: reason);
      _isSubmittingTeacherDecision = false;
      await loadPendingTeachers();
      await loadTeacherDetails(teacherId);
      notifyListeners();
      return true;
    } catch (e) {
      _teacherDecisionError = e.toString();
      _isSubmittingTeacherDecision = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDashboardOverview() async {
    _isLoadingDashboardOverview = true;
    _dashboardOverviewError = null;
    notifyListeners();
    try {
      _dashboardOverview = await _adminService.getDashboardOverview();
      _isLoadingDashboardOverview = false;
      notifyListeners();
    } catch (e) {
      _dashboardOverviewError = e.toString();
      _dashboardOverview = null;
      _isLoadingDashboardOverview = false;
      notifyListeners();
    }
  }

  Future<void> loadTeachers() async {
    _isLoadingTeachers = true;
    _teachersError = null;
    notifyListeners();
    try {
      final data = await _adminService.getTeachers(
        status: _teacherStatusFilter,
        search: _teacherSearchQuery.isEmpty ? null : _teacherSearchQuery,
      );
      _teachers = data.map((e) => UserModel.fromJson(e)).toList();
      _isLoadingTeachers = false;
      notifyListeners();
    } catch (e) {
      _teachersError = e.toString();
      _teachers = [];
      _isLoadingTeachers = false;
      notifyListeners();
    }
  }

  void setTeacherSearchQuery(String value) {
    _teacherSearchQuery = value;
    notifyListeners();
  }

  void setTeacherStatusFilter(String? value) {
    _teacherStatusFilter = value;
    notifyListeners();
  }

  Future<void> loadAdminLessons() async {
    _isLoadingAdminLessons = true;
    _adminLessonsError = null;
    notifyListeners();
    try {
      _adminLessons = await _adminService.getAdminLessons(
        search: _lessonSearchQuery.isEmpty ? null : _lessonSearchQuery,
        status: _lessonStatusFilter,
      );
      _isLoadingAdminLessons = false;
      notifyListeners();
    } catch (e) {
      _adminLessonsError = e.toString();
      _adminLessons = [];
      _isLoadingAdminLessons = false;
      notifyListeners();
    }
  }

  void setLessonSearchQuery(String value) {
    _lessonSearchQuery = value;
    notifyListeners();
  }

  void setLessonStatusFilter(String? value) {
    _lessonStatusFilter = value;
    notifyListeners();
  }

  Future<bool> moderateLesson(
    String lessonId, {
    required String status,
    String? moderationNote,
  }) async {
    _isSubmittingLessonModeration = true;
    _lessonModerationError = null;
    notifyListeners();
    try {
      await _adminService.moderateLesson(
        lessonId,
        status: status,
        moderationNote: moderationNote,
      );
      _isSubmittingLessonModeration = false;
      await Future.wait([loadAdminLessons(), loadDashboardOverview()]);
      notifyListeners();
      return true;
    } catch (e) {
      _lessonModerationError = e.toString();
      _isSubmittingLessonModeration = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadNotificationsOverview() async {
    _isLoadingNotificationsOverview = true;
    _notificationsOverviewError = null;
    notifyListeners();
    try {
      _notificationsOverview = await _adminService.getNotificationsOverview();
      _isLoadingNotificationsOverview = false;
      notifyListeners();
    } catch (e) {
      _notificationsOverviewError = e.toString();
      _notificationsOverview = null;
      _isLoadingNotificationsOverview = false;
      notifyListeners();
    }
  }
}
