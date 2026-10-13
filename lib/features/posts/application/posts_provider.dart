import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/post.dart';
import '../data/post_api.dart';
import '../data/post_repository.dart';

final postApiProvider = Provider<PostApi>((ref) {
  final dio = ref.watch(dioProvider);
  return PostApi(dio);
});     

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final postApi = ref.watch(postApiProvider);
  return PostRepository(postApi);
});   

final postsProvider =
    AsyncNotifierProvider<PostsController, List<Post>>(PostsController.new);

final postDetailsProvider = FutureProvider.family<Post, int>((ref, id) {
  return ref.watch(postRepositoryProvider).getPost(id);
});

class PostsController extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() {
    return ref.watch(postRepositoryProvider).getPosts();
  }

  Future<void> createPost({
    required String title,
    required String body,
  }) async {
    _loadedPosts();
    final created = await ref
        .read(postRepositoryProvider)
        .createPost(title: title, body: body);
    state = AsyncData([..._loadedPosts(), created]);
  }

  Future<void> updatePost(Post post) async {
    _loadedPosts();
    final updated = await ref.read(postRepositoryProvider).updatePost(post);
    state = AsyncData([
      for (final current in _loadedPosts())
        if (current.id == updated.id) updated else current,
    ]);
  }

  Future<void> deletePost(int id) async {
    _loadedPosts();
    await ref.read(postRepositoryProvider).deletePost(id);
    state = AsyncData(
      _loadedPosts().where((post) => post.id != id).toList(),
    );
  }

  List<Post> _loadedPosts() {
    final posts = state.asData?.value;
    if (posts == null) {
      throw StateError('Posts are not loaded.');
    }
    return posts;
  }
}