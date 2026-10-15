import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/navigation/presentation/home_screen.dart';
import '../../features/posts/presentation/post_details_screen.dart';
import '../../features/posts/presentation/posts_screen.dart';
import '../presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const posts = '/posts';
  static const auth = '/auth';
  static const profile = '/profile';
  static const settings = '/settings';
  static const postDetails = '/posts/:postId';

  static String postDetailsFor(int postId) => '/posts/$postId';
}

GoRouter createAppRouter({required AuthState Function() readAuthState}) {
  return GoRouter(
    redirect: (context, state) {
      final auth = readAuthState();
      final path = state.uri.path;
      final isProtected = path == AppRoutes.profile || path == AppRoutes.settings;

      if (isProtected && (!auth.isReady || !auth.isAuthenticated)) {
        return Uri(
          path: AppRoutes.auth,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      if (path == AppRoutes.auth && auth.isReady && auth.isAuthenticated) {
        final destination = state.uri.queryParameters['from'];
        if (destination == AppRoutes.profile ||
            destination == AppRoutes.settings) {
          return destination;
        }
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.posts,
        builder: (context, state) => const PostsScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.postDetails,
        builder: (context, state) {
          final postId = int.tryParse(state.pathParameters['postId']!);
          if (postId == null || postId <= 0) {
            return const Scaffold(
              body: Center(child: Text('Invalid post ID.')),
            );
          }
          return PostDetailsScreen(postId: postId);
        },
      ),
    ],
  );
}
