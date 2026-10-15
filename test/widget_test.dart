import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:post_manager/core/presentation/app_bar_actions.dart';
import 'package:post_manager/core/routing/app_router.dart';
import 'package:post_manager/features/auth/application/auth_provider.dart';
import 'package:post_manager/features/auth/presentation/auth_screen.dart';
import 'package:post_manager/features/posts/application/posts_provider.dart';
import 'package:post_manager/features/posts/data/post.dart';
import 'package:post_manager/features/posts/data/post_api.dart';
import 'package:post_manager/features/posts/data/post_repository.dart';
import 'package:post_manager/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    await _register(tester);
    await _openPosts(tester);

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

    await _openPosts(tester);

    await tester.tap(find.text('Existing title'));
    await tester.pumpAndSettle();

    expect(repository.lastRequestedPostId, 1);
    expect(find.text('Post details'), findsOneWidget);
    expect(find.text('Post ID: 1'), findsOneWidget);
    expect(find.text('Existing body'), findsOneWidget);
  });

  testWidgets('searches posts and paginates filtered results', (tester) async {
    final repository = _FakePostRepository(
      initialPosts: List.generate(
        12,
        (index) => Post(
          userId: 1,
          id: index + 1,
          title: 'Post title ${index + 1}',
          body: index == 11 ? 'A searchable needle' : 'Body ${index + 1}',
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await _openPosts(tester);

    expect(find.byKey(const ValueKey('post-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('post-search-field')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('posts-pagination-summary')),
      500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Showing 1–10 of 12 posts'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('posts-next-page')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Post title 11'),
      500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Showing 11–12 of 12 posts'), findsOneWidget);
    expect(find.text('Post title 11'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('posts-page-size')),
      -500,
      scrollable: _postsScrollable(),
    );
    await tester.tap(find.byKey(const ValueKey('posts-page-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('posts-pagination-summary')),
      500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Showing 1–5 of 12 posts'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('posts-page-size')),
      -500,
      scrollable: _postsScrollable(),
    );
    await tester.tap(find.byKey(const ValueKey('posts-page-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('posts-pagination-summary')),
      500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Showing 1–12 of 12 posts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Post title 12'),
      500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Post title 12'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('post-search')),
      -500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('post-search')), 'needle');
    await tester.pumpAndSettle();
    expect(find.text('No posts match your search.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('post-search-field')),
      -500,
      scrollable: _postsScrollable(),
    );
    await tester.tap(find.byKey(const ValueKey('post-search-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('posts-pagination-summary')),
      500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Post title 12'), findsOneWidget);
    expect(find.text('Showing 1–1 of 1 posts'), findsOneWidget);
  });

  testWidgets('pagination arrows fit and work on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakePostRepository(
      initialPosts: List.generate(
        12,
        (index) => Post(
          userId: 1,
          id: index + 1,
          title: 'Post title ${index + 1}',
          body: 'Body ${index + 1}',
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await _openPosts(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('posts-next-page')),
      500,
      scrollable: _postsScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('posts-previous-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('posts-next-page')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('posts-next-page')));
    await tester.pumpAndSettle();
    expect(find.text('Showing 11–12 of 12 posts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer navigates between Home and Posts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Post Manager'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();

    expect(find.text('Existing title'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Post Manager'), findsOneWidget);
  });

  testWidgets('authentication routes guests to login before profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(AppBarActions))).go(
      AppRoutes.profile,
    );
    await tester.pumpAndSettle();
    expect(find.text('Log in or register'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'demo@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password123',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Demo User'), findsOneWidget);
  });

  testWidgets('guests can view details but need an account to manage posts', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _openPosts(tester);
    expect(
      find.text(
        'You can view post details. Log in to create, edit, or delete posts.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add post'), findsNothing);
    expect(find.byTooltip('Post actions'), findsNothing);

    await tester.tap(find.text('Existing title'));
    await tester.pumpAndSettle();
    expect(find.text('Existing body'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _register(tester);
    await _openPosts(tester);
    expect(find.text('Add post'), findsOneWidget);
    expect(find.byTooltip('Post actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile and account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Add post'), findsNothing);
    expect(find.byTooltip('Post actions'), findsNothing);

    await tester.tap(find.byTooltip('Log in or register'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'demo@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password123',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    await _openPosts(tester);
    expect(find.text('Add post'), findsOneWidget);
    expect(find.byTooltip('Post actions'), findsOneWidget);
  });

  testWidgets('registration requires valid input and redirects to login', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Log in or register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    final registerButton = find.widgetWithText(FilledButton, 'Register');
    expect(tester.widget<FilledButton>(registerButton).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'Demo User');
    await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.pump();
    expect(tester.widget<FilledButton>(registerButton).onPressed, isNull);

    await tester.enterText(
      find.byType(TextFormField).at(1),
      'newuser@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.pump();
    expect(tester.widget<FilledButton>(registerButton).onPressed, isNotNull);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Account created. Log in to continue.'),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .join(' | '),
    );
    expect(find.byKey(const ValueKey('auth-submit')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'newuser@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password123',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
          .controller
          ?.text,
      'newuser@example.com',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-password')))
          .controller
          ?.text,
      'password123',
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(
      ProviderScope.containerOf(tester.element(find.byType(MyApp)))
          .read(authProvider)
          .isAuthenticated,
      isTrue,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .join(' | '),
    );
    expect(
      find.byTooltip('Profile and account menu'),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .join(' | '),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Profile and account menu'), findsOneWidget);
  });

  testWidgets('avatar menu opens profile and settings pages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await _register(tester);

    await tester.tap(find.byTooltip('Profile and account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('newuser@example.com'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile and account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Dark theme'), findsOneWidget);
  });

  testWidgets('authenticated users are redirected away from auth screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await _register(tester);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Post Manager'), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
    expect(find.byTooltip('Profile and account menu'), findsOneWidget);
  });

  testWidgets('theme toggle switches the app theme', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });
}

Future<void> _register(
  WidgetTester tester, {
  String email = 'newuser@example.com',
}) async {
  await tester.tap(find.byTooltip('Log in or register'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('New here? Create an account'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'Demo User');
  await tester.enterText(find.byType(TextFormField).at(1), email);
  await tester.enterText(find.byType(TextFormField).at(2), 'password123');
  await tester.pump();
  await tester.tap(find.text('Register'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('auth-email')), email);
  await tester.enterText(
    find.byKey(const ValueKey('auth-password')),
    'password123',
  );
  await tester.pump();
  expect(
    tester
        .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
        .onPressed,
    isNotNull,
  );
  await tester.tap(find.byKey(const ValueKey('auth-submit')));
  await tester.pumpAndSettle();
  expect(
    ProviderScope.containerOf(tester.element(find.byType(MyApp)))
        .read(authProvider)
        .isAuthenticated,
    isTrue,
  );
  expect(
    find.byTooltip('Profile and account menu'),
    findsOneWidget,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .join(' | '),
  );
}

Future<void> _openPosts(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Posts'));
  await tester.pumpAndSettle();
}

Finder _postsScrollable() => find
    .descendant(
      of: find.byKey(const ValueKey('posts-list')),
      matching: find.byType(Scrollable),
    )
    .first;

class _FakePostRepository extends PostRepository {
  _FakePostRepository({List<Post>? initialPosts})
    : posts =
          initialPosts ??
          [
            const Post(
              userId: 1,
              id: 1,
              title: 'Existing title',
              body: 'Existing body',
            ),
          ],
      super(PostApi(Dio()));

  final List<Post> posts;
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
