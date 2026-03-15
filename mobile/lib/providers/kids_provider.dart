import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class KidsProvider with ChangeNotifier {
  final ApiService _apiService;
  KidsProvider(this._apiService);

  List<dynamic> _kids = [];
  bool _isLoading = false;

  List<dynamic> get kids => _kids;
  bool get isLoading => _isLoading;

  Future<void> loadKids() async {
    _isLoading = true;
    notifyListeners();

    try {
      _kids = await _apiService.getKids();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> addKid({
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? grade,
    String? school,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.addKid(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        grade: grade,
        school: school,
      );
      await loadKids();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setPin({
    required String kidId,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.setPin(kidId: kidId, pin: pin);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyPin({
    required String kidId,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.verifyPin(kidId: kidId, pin: pin);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
