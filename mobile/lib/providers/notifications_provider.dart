import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NotificationsProvider with ChangeNotifier {
  final ApiService _apiService;

  NotificationsProvider(this._apiService);

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getNotifications(),
        _apiService.getUnreadNotificationsCount(),
      ]);
      final data = results[0] as List<dynamic>;
      _unreadCount = results[1] as int;
      _items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markRead(String id) async {
    await _apiService.markNotificationRead(id);
    await load();
  }
}
