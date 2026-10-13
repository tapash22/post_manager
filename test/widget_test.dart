import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_manager/features/posts/application/posts_provider.dart';
import 'package:post_manager/features/posts/data/post.dart';
import 'package:post_manager/features/posts/data/post_api.dart';
import 'package:post_manager/features/posts/data/post_repository.dart';
import 'package:post_manager/main.dart';

void main() {
  testWidgets('app bar fits a narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('creates, edits, and deletes a post', (tester) async {
    final repository = _FakePostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add post'));
    await tester.pumpAndSettle();

    final createButton = find.widgetWithText(FilledButton, 'Create post');
    expect(tester.widget<FilledButton>(createButton).onPressed, isNull);
    await tester.enterText(find.byType(TextFormField).at(0), 'A new title');
    await tester.pump();
    expect(tester.widget<FilledButton>(createButton).onPressed, isNull);
    await tester.enterText(find.byType(TextFormField).at(1), 'A new body');
    await tester.pump();
    expect(tester.widget<FilledButton>(createButton).onPressed, isNotNull);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('A new title'), findsOneWidget);
    expect(find.text('A new body'), findsOneWidget);
    expect(find.text('Post created successfully.'), findsOneWidget);

    await tester.tap(find.byTooltip('Post actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated title');
    await tester.enterText(find.byType(TextFormField).at(1), 'Updated body');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Updated title'), findsOneWidget);
    expect(find.text('Updated body'), findsOneWidget);
    expect(find.text('A new title'), findsNothing);

    await tester.tap(find.byTooltip('Post actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Updated title'), findsNothing);
    expect(repository.posts, hasLength(1));
  });

  testWidgets('opens post details and loads the selected post by ID', (
    tester,
  ) async {
    final repository = _FakePostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Existing title'));
    await tester.pumpAndSettle();

    expect(repository.lastRequestedPostId, 1);
    expect(find.text('Post details'), findsOneWidget);
    expect(find.text('Post ID: 1'), findsOneWidget);
    expect(find.text('Existing body'), findsOneWidget);
  });
}

class _FakePostRepository extends PostRepository {
  _FakePostRepository() : super(PostApi(Dio()));

  final List<Post> posts = [
    const Post(
      userId: 1,
      id: 1,
      title: 'Existing title',
      body: 'Existing body',
    ),
  ];
  int _nextId = 2;
  int? lastRequestedPostId;

  @override
  Future<List<Post>> getPosts() async => List.unmodifiable(posts);

  @override
  Future<Post> getPost(int id) async {
    lastRequestedPostId = id;
    return posts.firstWhere((post) => post.id == id);
  }

  @override
  Future<Post> createPost({required String title, required String body}) async {
    final post = Post(userId: 1, id: _nextId++, title: title, body: body);
    posts.add(post);
    return post;
  }

  @override
  Future<Post> updatePost(Post post) async {
    final index = posts.indexWhere((current) => current.id == post.id);
    posts[index] = post;
    return post;
  }

  @override
  Future<void> deletePost(int id) async {
    posts.removeWhere((post) => post.id == id);
  }
}
