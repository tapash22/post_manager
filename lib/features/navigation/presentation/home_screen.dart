import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/presentation/app_header_bar.dart';
import '../../../core/presentation/app_bar_actions.dart';
import '../../posts/application/posts_provider.dart';
import 'home_charts.dart';
import 'app_navigation_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final posts = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppHeaderBar(
        title: 'Home',
        icon: Icons.home_outlined,
        actions: const [AppBarActions()],
      ),
      drawer: const AppNavigationDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  onPressed: () => context.go(AppRoutes.posts),
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Manage posts'),
                ),
                const SizedBox(height: 32),
                Text(
                  'Post analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                posts.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Could not load post analytics: $error'),
                    ),
                  ),
                  data: (items) => HomeCharts(posts: items),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
