import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_header_bar.dart';
import '../application/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.name ?? 'User';

    return Scaffold(
      appBar: const AppHeaderBar(title: 'Profile', icon: Icons.person_outline),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(auth.email ?? ''),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
