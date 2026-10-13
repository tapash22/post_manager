import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/posts_provider.dart';
import '../data/post.dart';
import 'post_details_screen.dart';
import 'post_form_dialog.dart';
import 'widgets/post_card.dart';

class PostsScreen extends ConsumerStatefulWidget {
  const PostsScreen({super.key});

  @override
  ConsumerState<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends ConsumerState<PostsScreen> {
  Future<void> _openPostForm({Post? post}) async {
    final saved = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) => Center(
        child: PostFormDialog(
          post: post,
          onSave: (title, body) async {
            final controller = ref.read(postsProvider.notifier);
            if (post == null) {
              await controller.createPost(title: title, body: body);
            } else {
              await controller.updatePost(
                Post(
                  userId: post.userId,
                  id: post.id,
                  title: title,
                  body: body,
                ),
              );
            }
          },
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: slideAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(slideAnimation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(slideAnimation),
              child: child,
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      _showToast(
        post == null
            ? 'Post created successfully.'
            : 'Post updated successfully.',
      );
    }
  }

  Future<void> _deletePost(Post post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('“${post.title}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await ref.read(postsProvider.notifier).deletePost(post.id);
      if (!mounted) {
        return;
      }
      _showToast('Post deleted successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showToast('Could not delete post: $error', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? colorScheme.error : colorScheme.primary,
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? colorScheme.onError : colorScheme.onPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const Text(
          'Post Manager',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh posts',
            onPressed: () => ref.invalidate(postsProvider),
            icon: const Icon(Icons.refresh),
            constraints: const BoxConstraints.tightFor(width: 44, height: 48),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(postsProvider);
          await ref.read(postsProvider.future);
        },
        child: postsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 16),
              const Center(child: Text('Could not load posts.')),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(postsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: Text('No posts found.')),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: PostCard(
                      post: post,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              PostDetailsScreen(postId: post.id),
                        ),
                      ),
                      onEdit: () => _openPostForm(post: post),
                      onDelete: () => _deletePost(post),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: postsAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: _openPostForm,
              icon: const Icon(Icons.add),
              label: const Text('Add post'),
            )
          : null,
    );
  }
}
