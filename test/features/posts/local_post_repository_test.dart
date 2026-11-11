import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:post_manager/core/storage/app_database.dart';
import 'package:post_manager/features/posts/data/datasources/post_local_data_source.dart';
import 'package:post_manager/features/posts/data/models/post_hive_model.dart';
import 'package:post_manager/features/posts/data/repositories/local_post_repository.dart';
import 'package:post_manager/features/posts/domain/entities/post.dart';

void main() {
  late Directory directory;
  late LocalPostRepository repository;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('post-manager-posts-');
    await AppDatabase.initialize(directory: directory.path);
  });

  setUp(() async {
    await AppDatabase.posts.clear();
    repository = LocalPostRepository(PostLocalDataSource.fromDatabase());
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('creates, reads, updates, and deletes local posts', () async {
    final created = await repository.createPost(
      title: 'Local title',
      body: 'Local body',
    );
    expect(created.id, 1);
    expect(await repository.getPost(created.id), created);
    expect(await repository.getPosts(), [created]);

    final updated = Post(
      userId: created.userId,
      id: created.id,
      title: 'Updated title',
      body: 'Updated body',
    );
    await repository.updatePost(updated);
    expect(await repository.getPost(created.id), updated);

    await repository.deletePost(created.id);
    expect(await repository.getPosts(), isEmpty);
    await expectLater(
      repository.getPost(created.id),
      throwsA(isA<PostNotFoundException>()),
    );
  });

  test('rejects duplicate IDs and updates to missing IDs', () async {
    await AppDatabase.posts.put(
      1,
      PostHiveModel(id: 5, userId: 1, title: 'First', body: 'First body'),
    );
    await AppDatabase.posts.put(
      6,
      PostHiveModel(id: 3, userId: 1, title: 'Duplicate key', body: 'Body'),
    );
    await expectLater(
      repository.createPost(title: 'New', body: 'Body'),
      throwsStateError,
    );
    await expectLater(
      repository.updatePost(
        const Post(userId: 1, id: 99, title: 'Missing', body: 'Body'),
      ),
      throwsA(isA<PostNotFoundException>()),
    );
  });

  test('persists posts after Hive boxes are reopened', () async {
    final created = await repository.createPost(
      title: 'Persistent post',
      body: 'Saved locally',
    );

    await Hive.close();
    await AppDatabase.initialize(directory: directory.path);
    repository = LocalPostRepository(PostLocalDataSource.fromDatabase());

    expect(await repository.getPost(created.id), created);
  });
}
