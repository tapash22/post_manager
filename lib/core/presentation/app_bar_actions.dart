import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../application/theme_provider.dart';
import 'settings_screen.dart';

class AppBarActions extends ConsumerWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: themeMode == ThemeMode.dark
              ? 'Switch to light theme'
              : 'Switch to dark theme',
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
        ),
        if (auth.isAuthenticated)
          PopupMenuButton<String>(
            tooltip: 'Profile and account menu',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 17,
                child: Text(auth.name!.substring(0, 1).toUpperCase()),
              ),
            ),
            onSelected: (action) async {
              switch (action) {
                case 'profile':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                case 'settings':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                case 'logout':
                  try {
                    await ref.read(authProvider.notifier).logout();
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not log out: $error')),
                      );
                    }
                  }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text('Signed in as ${auth.name}'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
          )
        else if (!auth.isReady)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            tooltip: 'Log in or register',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => const AuthScreen()),
            ),
            icon: const Icon(Icons.login),
          ),
      ],
    );
  }
}
