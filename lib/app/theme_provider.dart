import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode preference key
const String _themePreferenceKey = 'theme_mode';

/// Theme mode state notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemePreference();
  }

  /// Load saved theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePreferenceKey);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      state = ThemeMode.values[themeIndex];
    }
  }

  /// Save theme preference
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, mode.index);
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemePreference(mode);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Check if dark mode is enabled
  bool get isDarkMode => state == ThemeMode.dark;

  /// Check if system theme is used
  bool get isSystemTheme => state == ThemeMode.system;
}

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Helper to get the effective brightness based on theme mode and platform
extension ThemeModeExtension on ThemeMode {
  Brightness getEffectiveBrightness(BuildContext context) {
    switch (this) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
    }
  }
}
