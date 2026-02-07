import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocaleKey = 'selected_locale';

/// A Notifier that manages the app's [Locale].
/// It persists the user's choice to [SharedPreferences].
class LocaleNotifier extends Notifier<Locale> {
  late SharedPreferences _prefs;
  Locale? _initialLocale;

  /// Optional: Set the initial locale during ProviderScope initialization.
  void setInitialLocale(Locale locale) {
    _initialLocale = locale;
  }

  @override
  Locale build() {
    return _initialLocale ?? const Locale('bn');
  }

  /// Sets the locale and persists it.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString(_kLocaleKey, locale.languageCode);
  }

  /// Toggles between languages (English and Bangla)
  Future<void> toggleLocale() async {
    final currentCode = state.languageCode;
    Locale newLocale;

    if (currentCode == 'en') {
      newLocale = const Locale('bn');
    } else {
      newLocale = const Locale('en');
    }

    await setLocale(newLocale);
  }
}

/// Provider for the app's locale.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

/// Helper to get the saved locale code during app startup.
Future<String?> getSavedLocaleCode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kLocaleKey);
}
