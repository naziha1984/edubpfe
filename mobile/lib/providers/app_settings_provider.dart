import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences globales : langue d’affichage (welcome + shell) et thème clair/sombre.
class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider();

  static const _kLocale = 'app_locale';
  static const _kTheme = 'app_theme_mode';

  Locale _locale = const Locale.fromSubtags(languageCode: 'fr');
  ThemeMode _themeMode = ThemeMode.system;
  bool _ready = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isReady => _ready;

  String get languageCode => _locale.languageCode;

  /// À appeler une fois au démarrage (ex. depuis `provider` create).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final loc = prefs.getString(_kLocale) ?? 'fr';
    final themeStr = prefs.getString(_kTheme) ?? 'system';
    _locale = Locale(loc);
    _themeMode = _themeModeFromStorage(themeStr);
    _ready = true;
    notifyListeners();
  }

  static ThemeMode _themeModeFromStorage(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _storageFromThemeMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setLocale(Locale value) async {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, value.languageCode);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, _storageFromThemeMode(value));
  }

}
