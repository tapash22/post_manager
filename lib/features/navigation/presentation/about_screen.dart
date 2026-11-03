import 'package:flutter/material.dart';

import '../../../core/presentation/app_bar_actions.dart';
import '../../../core/presentation/app_header_bar.dart';
import 'app_navigation_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppHeaderBar(
        title: 'About',
        icon: Icons.info_outline,
        actions: const [AppBarActions()],
      ),
      drawer: const AppNavigationDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.article_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'About Post Manager',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Post Manager helps you browse, search, and organize posts. '
                  'Sign in to create, edit, and delete posts.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
