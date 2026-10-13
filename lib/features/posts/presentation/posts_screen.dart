import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_bar_actions.dart';
import '../../auth/application/auth_provider.dart';
import '../../navigation/presentation/app_navigation_drawer.dart';
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
  final _searchController = TextEditingController();
  PostSearchField _searchField = PostSearchField.title;
  int _pageSize = 10;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      drawer: const AppNavigationDrawer(postsSelected: true),
      appBar: AppBar(
        titleSpacing: 12,
        title: const Text(
          'Post Manager',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const AppBarActions(),
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
            final query = _searchController.text.trim().toLowerCase();
            final filteredPosts = posts.where((post) {
              if (query.isEmpty) {
                return true;
              }
              final searchableText = switch (_searchField) {
                PostSearchField.title => post.title,
                PostSearchField.body => post.body,
              };
              return searchableText.toLowerCase().contains(query);
            }).toList();
            final pageCount = _pageSize == -1 || filteredPosts.isEmpty
                ? 1
                : (filteredPosts.length / _pageSize).ceil();
            final safePage = _currentPage.clamp(0, pageCount - 1).toInt();
            final startIndex = safePage * _pageSize;
            final endIndex = _pageSize == -1
                ? filteredPosts.length
                : (startIndex + _pageSize)
                      .clamp(0, filteredPosts.length)
                      .toInt();
            final visiblePosts = _pageSize == -1
                ? filteredPosts
                : filteredPosts.sublist(startIndex, endIndex);

            return ListView(
              key: const ValueKey('posts-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _searchControls(),
                if (!isAuthenticated) _guestNotice(context),
                if (visiblePosts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 56),
                    child: Center(
                      child: Text(
                        query.isEmpty
                            ? 'No posts found.'
                            : 'No posts match your search.',
                      ),
                    ),
                  )
                else
                  for (final post in visiblePosts)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: PostCard(
                          post: post,
                          canManage: isAuthenticated,
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
                    ),
                _paginationControls(
                  resultCount: filteredPosts.length,
                  startIndex: startIndex,
                  endIndex: endIndex,
                  pageCount: pageCount,
                  currentPage: safePage,
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: postsAsync.hasValue && isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: _openPostForm,
              icon: const Icon(Icons.add),
              label: const Text('Add post'),
            )
          : null,
    );
  }

  Widget _searchControls() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  key: const ValueKey('post-search'),
                  controller: _searchController,
                  onChanged: (_) => setState(() => _currentPage = 0),
                  decoration: InputDecoration(
                    labelText: 'Search posts',
                    hintText: 'Enter a title or body phrase',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _currentPage = 0);
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Search in'),
                        const SizedBox(width: 8),
                        DropdownButton<PostSearchField>(
                          key: const ValueKey('post-search-field'),
                          value: _searchField,
                          items: const [
                            DropdownMenuItem(
                              value: PostSearchField.title,
                              child: Text('Title'),
                            ),
                            DropdownMenuItem(
                              value: PostSearchField.body,
                              child: Text('Body'),
                            ),
                          ],
                          onChanged: (field) {
                            if (field != null) {
                              setState(() {
                                _searchField = field;
                                _currentPage = 0;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Per page'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          key: const ValueKey('posts-page-size'),
                          value: _pageSize,
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5')),
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 20, child: Text('20')),
                            DropdownMenuItem(value: -1, child: Text('All')),
                          ],
                          onChanged: (size) {
                            if (size != null) {
                              setState(() {
                                _pageSize = size;
                                _currentPage = 0;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginationControls({
    required int resultCount,
    required int startIndex,
    required int endIndex,
    required int pageCount,
    required int currentPage,
  }) {
    final firstShown = resultCount == 0 ? 0 : startIndex + 1;
    final lastShown = endIndex;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                resultCount == 0
                    ? 'Showing 0 of 0 posts'
                    : 'Showing $firstShown–$lastShown of $resultCount posts',
                key: const ValueKey('posts-pagination-summary'),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('posts-previous-page'),
                    tooltip: 'Previous page',
                    onPressed: currentPage == 0
                        ? null
                        : () => setState(() => _currentPage = currentPage - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    _pageSize == -1
                        ? 'All posts'
                        : 'Page ${currentPage + 1} of $pageCount',
                  ),
                  IconButton(
                    key: const ValueKey('posts-next-page'),
                    tooltip: 'Next page',
                    onPressed: currentPage + 1 >= pageCount
                        ? null
                        : () => setState(() => _currentPage = currentPage + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guestNotice(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can view post details. Log in to create, edit, or delete posts.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum PostSearchField { title, body }
