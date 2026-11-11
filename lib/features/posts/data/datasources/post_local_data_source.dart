import 'package:hive_ce/hive.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/post.dart';
import '../models/post_hive_model.dart';

class PostLocalDataSource {
  PostLocalDataSource(this._box);

  final Box<PostHiveModel> _box;

  factory PostLocalDataSource.fromDatabase() =>
      PostLocalDataSource(AppDatabase.posts);

  List<Post> getPosts() {
    final posts = _box.values.map(_toEntity).toList()
      ..sort((first, second) => first.id.compareTo(second.id));
    return posts;
  }

  Post getPost(int id) {
    final model = _box.get(id);
    if (model == null) {
      throw PostNotFoundException(id);
    }
    return _toEntity(model);
  }

  Future<Post> createPost({required String title, required String body}) async {
    final id = _box.isEmpty
        ? 1
        : _box.values.map((post) => post.id).reduce((a, b) => a > b ? a : b) +
              1;
    if (_box.containsKey(id)) {
      throw StateError('A post with ID $id already exists.');
    }
    final model = PostHiveModel(id: id, userId: 1, title: title, body: body);
    await _box.put(id, model);
    return _toEntity(model);
  }

  Future<Post> updatePost(Post post) async {
    if (!_box.containsKey(post.id)) {
      throw PostNotFoundException(post.id);
    }
    final model = PostHiveModel(
      id: post.id,
      userId: post.userId,
      title: post.title,
      body: post.body,
    );
    await _box.put(post.id, model);
    return _toEntity(model);
  }

  Future<void> deletePost(int id) async {
    if (!_box.containsKey(id)) {
      throw PostNotFoundException(id);
    }
    await _box.delete(id);
  }

  Post _toEntity(PostHiveModel model) => Post(
    userId: model.userId,
    id: model.id,
    title: model.title,
    body: model.body,
  );
}

class PostNotFoundException implements Exception {
  const PostNotFoundException(this.id);

  final int id;

  @override
  String toString() => 'Post with ID $id was not found.';
}
