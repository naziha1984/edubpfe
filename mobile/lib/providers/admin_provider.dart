import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/admin_kid_model.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';

/// Provider pour gérer les données admin (KPIs, users, kids)
class AdminProvider with ChangeNotifier {
  final AdminService _adminService;
  
  // KPIs
  int _totalUsers = 0;
  int _totalSubjects = 0;
  int _totalLessons = 0;
  bool _isLoadingStats = false;
  String? _statsError;

  // Users
  List<UserModel> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;
  String _searchQuery = '';
  String? _roleFilter;

  // Kids (liste admin)
  List<AdminKidModel> _kids = [];
  bool _isLoadingKids = false;
  String? _kidsError;

  AdminProvider(ApiService apiService)
      : _adminService = AdminService(apiService);

  // Getters pour KPIs
  int get totalUsers => _totalUsers;
  int get totalSubjects => _totalSubjects;
  int get totalLessons => _totalLessons;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  // Getters pour Users
  List<UserModel> get users => _users;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;
  String get searchQuery => _searchQuery;
  String? get roleFilter => _roleFilter;

  // Getters pour Kids
  List<AdminKidModel> get kids => _kids;
  bool get isLoadingKids => _isLoadingKids;
  String? get kidsError => _kidsError;

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
    // Recharger les users avec le nouveau filtre
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
}
