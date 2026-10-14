import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_header_bar.dart';
import '../../../core/presentation/app_bar_actions.dart';
import '../application/posts_provider.dart';

class PostDetailsScreen extends ConsumerWidget {
  final int postId;

  const PostDetailsScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailsProvider(postId));

    return Scaffold(
      appBar: AppHeaderBar(
        title: 'Post details',
        icon: Icons.article_outlined,
        actions: const [AppBarActions()],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load post details.'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref.invalidate(postDetailsProvider(postId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (post) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Post ID: ${post.id}')),
                    Chip(label: Text('User ID: ${post.userId}')),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  post.body,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
