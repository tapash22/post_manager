import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appSettingsStorageProvider = Provider<AppSettingsStorage>(
  (ref) => AppSettingsStorage(),
);

class AppSettingsStorage {
  static const _themeModeKey = 'post_manager_theme_mode';

  Future<ThemeMode> readThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_themeModeKey);
    return ThemeMode.values.where((mode) => mode.name == value).firstOrNull ??
        ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_themeModeKey, mode.name);
    if (!saved) {
      throw StateError('Could not save the theme preference.');
    }
  }
}
