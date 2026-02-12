import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'selected_theme_mode';

/// A Notifier that manages the app's [ThemeMode].
/// It persists the user's choice to [SharedPreferences].
class ThemeNotifier extends Notifier<ThemeMode> {
  late SharedPreferences _prefs;
  ThemeMode? _initialThemeMode;

  /// Optional: Set the initial theme mode during ProviderScope initialization.
  void setInitialThemeMode(ThemeMode mode) {
    _initialThemeMode = mode;
  }

  @override
  ThemeMode build() {
    return _initialThemeMode ?? ThemeMode.system;
  }

  /// Sets the theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString(_kThemeModeKey, mode.name);
  }

  /// Toggles between Light and Dark modes (skips System)
  Future<void> toggleTheme() async {
    ThemeMode newMode;

    if (state == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      newMode = ThemeMode.light;
    } else {
      // If currently System, switch to Light
      newMode = ThemeMode.light;
    }

    await setThemeMode(newMode);
  }
}

/// Provider for the app's theme mode.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

/// Helper to get the saved theme mode during app startup.
Future<ThemeMode> getSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeString = prefs.getString(_kThemeModeKey);

  if (themeModeString == null) {
    return ThemeMode.system;
  }

  switch (themeModeString) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.system;
  }
}
