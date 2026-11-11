import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_settings_storage.dart';

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() =>
      ref.watch(appSettingsStorageProvider).readThemeMode();

  Future<void> toggle() async {
    final current = state.asData?.value ?? ThemeMode.light;
    final next = current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await ref.read(appSettingsStorageProvider).saveThemeMode(next);
    state = AsyncData(next);
  }
}
