import '../entities/post.dart';

abstract interface class PostRepository {
  Future<List<Post>> getPosts();

  Future<Post> getPost(int id);

  Future<Post> createPost({required String title, required String body});

  Future<Post> updatePost(Post post);

  Future<void> deletePost(int id);
}
