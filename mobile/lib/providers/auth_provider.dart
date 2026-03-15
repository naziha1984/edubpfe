import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  AuthProvider(this._apiService);

  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get user => _userModel;
  Map<String, dynamic>? get userMap => _userModel?.toJson();
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get _token => _apiService.token;

  // Role helpers
  bool get isAdmin => _userModel?.isAdmin ?? false;
  bool get isTeacher => _userModel?.isTeacher ?? false;
  bool get isParent => _userModel?.isParent ?? false;
  String? get userRole => _userModel?.role;

  /// [role] : 'PARENT' ou 'TEACHER' (défaut 'PARENT')
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'PARENT',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      if (response['access_token'] != null) {
        await loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['access_token'] != null) {
        await loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadProfile() async {
    try {
      final userData = await _apiService.getProfile();
      debugPrint('🔐 [AuthProvider] Raw profile data: $userData');
      
      _userModel = UserModel.fromJson(userData);
      
      // Debug log pour vérifier le rôle
      debugPrint('🔐 [AuthProvider] ========== USER PROFILE LOADED ==========');
      debugPrint('🔐 [AuthProvider] User ID: ${_userModel?.id}');
      debugPrint('🔐 [AuthProvider] User Name: ${_userModel?.fullName}');
      debugPrint('🔐 [AuthProvider] User Email: ${_userModel?.email}');
      debugPrint('🔐 [AuthProvider] Raw Role from JSON: ${userData['role']}');
      debugPrint('🔐 [AuthProvider] Parsed Role: ${_userModel?.role}');
      debugPrint('🔐 [AuthProvider] IsAdmin: ${_userModel?.isAdmin}');
      debugPrint('🔐 [AuthProvider] IsTeacher: ${_userModel?.isTeacher}');
      debugPrint('🔐 [AuthProvider] IsParent: ${_userModel?.isParent}');
      debugPrint('🔐 [AuthProvider] =========================================');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error loading profile: $e');
      debugPrint('❌ [AuthProvider] Stack trace: ${StackTrace.current}');
      // Handle error
    }
  }

  void logout() {
    _apiService.setToken(null);
    _apiService.setKidToken(null);
    _userModel = null;
    notifyListeners();
  }
}
