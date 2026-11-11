import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/app_bar_actions.dart';
import '../../../core/presentation/app_header_bar.dart';
import '../../../core/presentation/smooth_state_switcher.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/application/auth_provider.dart';
import '../../navigation/presentation/app_navigation_drawer.dart';
import '../application/posts_provider.dart';
import '../domain/entities/post.dart';
import 'post_form_dialog.dart';
import 'widgets/post_card.dart';

class PostsScreen extends ConsumerStatefulWidget {
  const PostsScreen({super.key});

  @override
  ConsumerState<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends ConsumerState<PostsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(postsFilterProvider).query;
  }

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
    ref.listen(postsFilterProvider, (previous, next) {
      if (_searchController.text != next.query) {
        _searchController.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });
    final postsAsync = ref.watch(postsPageProvider);
    final filters = ref.watch(postsFilterProvider);
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppHeaderBar(
        title: 'Post Manager',
        icon: Icons.article_outlined,
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
        child: SmoothStateSwitcher(
          child: postsAsync.when(
            loading: () => ListView(
              key: const ValueKey('posts-loading'),
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (error, stackTrace) => ListView(
              key: const ValueKey('posts-error'),
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
            data: (page) {
              return ListView(
                key: const ValueKey('posts-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _searchControls(filters),
                  if (!isAuthenticated) _guestNotice(context),
                  if (page.posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 56),
                      child: Center(
                        child: Text(
                          filters.query.trim().isEmpty
                              ? 'No posts found.'
                              : 'No posts match your search.',
                        ),
                      ),
                    )
                  else
                    for (final post in page.posts)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: PostCard(
                            post: post,
                            canManage: isAuthenticated,
                            onTap: () =>
                                context.push(AppRoutes.postDetailsFor(post.id)),
                            onEdit: () => _openPostForm(post: post),
                            onDelete: () => _deletePost(post),
                          ),
                        ),
                      ),
                  _paginationControls(page: page, pageSize: filters.pageSize),
                ],
              );
            },
          ),
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

  Widget _searchControls(PostsFilterState filters) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('post-search'),
                      controller: _searchController,
                      onChanged: ref
                          .read(postsFilterProvider.notifier)
                          .setQuery,
                      decoration: InputDecoration(
                        hintText: 'Search posts',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(postsFilterProvider.notifier)
                                      .setQuery('');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Tooltip(
                      message: 'Search in title or body',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PostSearchField>(
                          key: const ValueKey('post-search-field'),
                          value: filters.searchField,
                          items: const [
                            DropdownMenuItem(
                              value: PostSearchField.title,
                              child: Text('Title'),
                            ),
                            DropdownMenuItem(
                              value: PostSearchField.body,
                              child: Text('Body'),
                            ),
                            DropdownMenuItem(
                              value: PostSearchField.titleAndBody,
                              child: Text('Title + body'),
                            ),
                          ],
                          onChanged: (field) {
                            if (field != null) {
                              ref
                                  .read(postsFilterProvider.notifier)
                                  .setSearchField(field);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginationControls({required PostsPage page, required int pageSize}) {
    final firstShown = page.totalCount == 0 ? 0 : page.startIndex + 1;
    final lastShown = page.endIndex;
    final summary = Text(
      page.totalCount == 0
          ? 'Showing 0 of 0 posts'
          : 'Showing $firstShown–$lastShown of ${page.totalCount} posts',
      key: const ValueKey('posts-pagination-summary'),
    );
    final pageSizeSelector = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Per page'),
        const SizedBox(width: 8),
        DropdownButton<int>(
          key: const ValueKey('posts-page-size'),
          value: pageSize,
          items: const [
            DropdownMenuItem(value: 5, child: Text('5')),
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
            DropdownMenuItem(value: -1, child: Text('All')),
          ],
          onChanged: (size) {
            if (size != null) {
              ref.read(postsFilterProvider.notifier).setPageSize(size);
            }
          },
        ),
      ],
    );
    final pageNavigation = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('posts-previous-page'),
          tooltip: 'Previous page',
          onPressed: page.page == 0
              ? null
              : () => ref
                    .read(postsFilterProvider.notifier)
                    .setPage(page.page - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          pageSize == -1
              ? 'All posts'
              : 'Page ${page.page + 1} of ${page.pageCount}',
        ),
        IconButton(
          key: const ValueKey('posts-next-page'),
          tooltip: 'Next page',
          onPressed: page.page + 1 >= page.pageCount
              ? null
              : () => ref
                    .read(postsFilterProvider.notifier)
                    .setPage(page.page + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    summary,
                    const SizedBox(height: 8),
                    pageSizeSelector,
                    const SizedBox(height: 8),
                    pageNavigation,
                  ],
                );
              }

              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [summary, pageSizeSelector, pageNavigation],
              );
            },
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
