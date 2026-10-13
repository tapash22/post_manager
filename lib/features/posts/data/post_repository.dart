import 'post.dart';
import 'post_api.dart';

class PostRepository {
  final PostApi _postApi;

  PostRepository(this._postApi);

  Future<List<Post>> getPosts() {
    return _postApi.fetchPosts();
  }

  Future<Post> getPost(int id) {
    return _postApi.fetchPost(id);
  }

  Future<Post> createPost({
    required String title,
    required String body,
  }) {
    return _postApi.createPost(title: title, body: body);
  }

  Future<Post> updatePost(Post post) {
    return _postApi.updatePost(post);
  }

  Future<void> deletePost(int id) {
    return _postApi.deletePost(id);
  }
}