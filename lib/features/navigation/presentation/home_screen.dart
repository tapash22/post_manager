import 'package:flutter/material.dart';

import '../../../core/presentation/app_header_bar.dart';
import '../../../core/presentation/app_bar_actions.dart';
import '../../posts/presentation/posts_screen.dart';
import 'app_navigation_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppHeaderBar(
        title: 'Home',
        icon: Icons.home_outlined,
        actions: const [AppBarActions()],
      ),
      drawer: const AppNavigationDrawer(postsSelected: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.dashboard_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Post Manager',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create, organize, and manage your posts in one place.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const PostsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Manage posts'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
