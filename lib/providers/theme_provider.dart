import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._(this._preferences, this._themeMode);

  static const _themeModePreferenceKey = 'theme_mode';

  final SharedPreferences _preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static Future<ThemeProvider> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModePreferenceKey);
    final themeMode = switch (savedMode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    return ThemeProvider._(preferences, themeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await _preferences.setString(_themeModePreferenceKey, value);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> toggleTheme() =>
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
}
