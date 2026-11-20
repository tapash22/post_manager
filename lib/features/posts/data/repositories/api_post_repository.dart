import '../../domain/entities/post.dart';
import '../datasources/post_api_data_source.dart';
import '../../domain/repositories/post_repository.dart';

/// Reads the public post list from JSONPlaceholder and keeps mutations local.
class ApiPostRepository implements PostRepository {
  const ApiPostRepository(this._api);

  final PostApiDataSource _api;

  @override
  Future<List<Post>> getPosts() => _api.getPosts();

  @override
  Future<Post> getPost(int id) async {
    final posts = await _api.getPosts();
    return posts.firstWhere((post) => post.id == id);
  }

  @override
  Future<Post> createPost({required String title, required String body}) =>
      _api.createPost(title: title, body: body);

  @override
  Future<Post> updatePost(Post post) => _api.updatePost(post);

  @override
  Future<void> deletePost(int id) => _api.deletePost(id);
}
