import '../entities/post.dart';
import '../repositories/post_repository.dart';

class GetPosts {
  const GetPosts(this._repository);

  final PostRepository _repository;

  Future<List<Post>> call() => _repository.getPosts();
}

class GetPost {
  const GetPost(this._repository);

  final PostRepository _repository;

  Future<Post> call(int id) => _repository.getPost(id);
}

class CreatePost {
  const CreatePost(this._repository);

  final PostRepository _repository;

  Future<Post> call({required String title, required String body}) =>
      _repository.createPost(title: title, body: body);
}

class UpdatePost {
  const UpdatePost(this._repository);

  final PostRepository _repository;

  Future<Post> call(Post post) => _repository.updatePost(post);
}

class DeletePost {
  const DeletePost(this._repository);

  final PostRepository _repository;

  Future<void> call(int id) => _repository.deletePost(id);
}
