import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/datasources/post_local_data_source.dart';
import '../data/repositories/local_post_repository.dart';
import '../domain/entities/post.dart';
import '../domain/repositories/post_repository.dart';
import '../domain/usecases/post_use_cases.dart';

final postLocalDataSourceProvider = Provider<PostLocalDataSource>(
  (ref) => PostLocalDataSource.fromDatabase(),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => LocalPostRepository(ref.watch(postLocalDataSourceProvider)),
);

final getPostsProvider = Provider<GetPosts>(
  (ref) => GetPosts(ref.watch(postRepositoryProvider)),
);
final getPostProvider = Provider<GetPost>(
  (ref) => GetPost(ref.watch(postRepositoryProvider)),
);
final createPostProvider = Provider<CreatePost>(
  (ref) => CreatePost(ref.watch(postRepositoryProvider)),
);
final updatePostProvider = Provider<UpdatePost>(
  (ref) => UpdatePost(ref.watch(postRepositoryProvider)),
);
final deletePostProvider = Provider<DeletePost>(
  (ref) => DeletePost(ref.watch(postRepositoryProvider)),
);

final postsProvider = AsyncNotifierProvider<PostsController, List<Post>>(
  PostsController.new,
);

final postDetailsProvider = FutureProvider.family<Post, int>((ref, id) {
  return ref.watch(getPostProvider)(id);
});

final postsFilterProvider =
    NotifierProvider<PostsFilterController, PostsFilterState>(
      PostsFilterController.new,
    );

final postsPageProvider = Provider<AsyncValue<PostsPage>>((ref) {
  final posts = ref.watch(postsProvider);
  final filter = ref.watch(postsFilterProvider);
  return posts.whenData((allPosts) {
    final query = filter.query.trim().toLowerCase();
    final filtered = allPosts.where((post) {
      if (query.isEmpty) {
        return true;
      }
      final searchableText = switch (filter.searchField) {
        PostSearchField.title => post.title,
        PostSearchField.body => post.body,
        PostSearchField.titleAndBody => '${post.title}\n${post.body}',
      };
      return searchableText.toLowerCase().contains(query);
    }).toList();

    final pageCount = filter.pageSize == -1 || filtered.isEmpty
        ? 1
        : (filtered.length / filter.pageSize).ceil();
    final page = filter.page.clamp(0, pageCount - 1).toInt();
    final start = page * (filter.pageSize == -1 ? 0 : filter.pageSize);
    final end = filter.pageSize == -1
        ? filtered.length
        : (start + filter.pageSize).clamp(0, filtered.length).toInt();
    return PostsPage(
      posts: filter.pageSize == -1 ? filtered : filtered.sublist(start, end),
      totalCount: filtered.length,
      pageCount: pageCount,
      page: page,
      startIndex: start,
      endIndex: end,
    );
  });
});

class PostsController extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() => ref.watch(getPostsProvider)();

  Future<void> createPost({required String title, required String body}) async {
    _requireAuthentication();
    _loadedPosts();
    final created = await ref
        .read(createPostProvider)
        .call(title: title, body: body);
    state = AsyncData([..._loadedPosts(), created]);
  }

  Future<void> updatePost(Post post) async {
    _requireAuthentication();
    _loadedPosts();
    final updated = await ref.read(updatePostProvider)(post);
    state = AsyncData([
      for (final current in _loadedPosts())
        if (current.id == updated.id) updated else current,
    ]);
    ref.invalidate(postDetailsProvider(post.id));
  }

  Future<void> deletePost(int id) async {
    _requireAuthentication();
    _loadedPosts();
    await ref.read(deletePostProvider)(id);
    state = AsyncData(_loadedPosts().where((post) => post.id != id).toList());
    ref.invalidate(postDetailsProvider(id));
  }

  List<Post> _loadedPosts() {
    final posts = state.asData?.value;
    if (posts == null) {
      throw StateError('Posts are not loaded.');
    }
    return posts;
  }

  void _requireAuthentication() {
    if (!ref.read(authProvider).isAuthenticated) {
      throw StateError('Log in to create, edit, or delete posts.');
    }
  }
}

class PostsFilterState {
  const PostsFilterState({
    this.query = '',
    this.searchField = PostSearchField.title,
    this.pageSize = 10,
    this.page = 0,
  });

  final String query;
  final PostSearchField searchField;
  final int pageSize;
  final int page;
}

class PostsFilterController extends Notifier<PostsFilterState> {
  @override
  PostsFilterState build() => const PostsFilterState();

  void setQuery(String query) {
    if (query != state.query) {
      state = PostsFilterState(
        query: query,
        searchField: state.searchField,
        pageSize: state.pageSize,
      );
    }
  }

  void setSearchField(PostSearchField field) {
    if (field != state.searchField) {
      state = PostsFilterState(
        query: state.query,
        searchField: field,
        pageSize: state.pageSize,
      );
    }
  }

  void setPageSize(int pageSize) {
    if (pageSize != state.pageSize) {
      state = PostsFilterState(
        query: state.query,
        searchField: state.searchField,
        pageSize: pageSize,
      );
    }
  }

  void setPage(int page) {
    state = PostsFilterState(
      query: state.query,
      searchField: state.searchField,
      pageSize: state.pageSize,
      page: page < 0 ? 0 : page,
    );
  }
}

class PostsPage {
  const PostsPage({
    required this.posts,
    required this.totalCount,
    required this.pageCount,
    required this.page,
    required this.startIndex,
    required this.endIndex,
  });

  final List<Post> posts;
  final int totalCount;
  final int pageCount;
  final int page;
  final int startIndex;
  final int endIndex;
}

enum PostSearchField { title, body, titleAndBody }
