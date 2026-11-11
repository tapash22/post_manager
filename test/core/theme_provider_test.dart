import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_manager/core/application/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores the theme preference', () async {
    final firstContainer = ProviderContainer();
    expect(
      await firstContainer.read(themeModeProvider.future),
      ThemeMode.light,
    );
    await firstContainer.read(themeModeProvider.notifier).toggle();
    firstContainer.dispose();

    final restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);
    expect(
      await restoredContainer.read(themeModeProvider.future),
      ThemeMode.dark,
    );
  });
}
