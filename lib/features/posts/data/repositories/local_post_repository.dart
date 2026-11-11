import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_local_data_source.dart';

class LocalPostRepository implements PostRepository {
  const LocalPostRepository(this._dataSource);

  final PostLocalDataSource _dataSource;

  @override
  Future<List<Post>> getPosts() async => _dataSource.getPosts();

  @override
  Future<Post> getPost(int id) async => _dataSource.getPost(id);

  @override
  Future<Post> createPost({required String title, required String body}) =>
      _dataSource.createPost(title: title, body: body);

  @override
  Future<Post> updatePost(Post post) => _dataSource.updatePost(post);

  @override
  Future<void> deletePost(int id) => _dataSource.deletePost(id);
}
