import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_header_bar.dart';
import '../application/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.light;

    return Scaffold(
      appBar: const AppHeaderBar(
        title: 'Settings',
        icon: Icons.settings_outlined,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark theme'),
            subtitle: const Text('Use a dark appearance throughout the app'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) async {
              try {
                await ref.read(themeModeProvider.notifier).toggle();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not update theme: $error')),
                  );
                }
              }
            },
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
    );
  }
}
