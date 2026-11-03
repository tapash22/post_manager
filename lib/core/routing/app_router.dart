import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/navigation/presentation/about_screen.dart';
import '../../features/navigation/presentation/home_screen.dart';
import '../../features/posts/presentation/post_details_screen.dart';
import '../../features/posts/presentation/posts_screen.dart';
import '../presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const posts = '/posts';
  static const about = '/about';
  static const auth = '/auth';
  static const profile = '/profile';
  static const settings = '/settings';
  static const postDetails = '/posts/:postId';

  static String postDetailsFor(int postId) => '/posts/$postId';
}

class AppNavigationDestination {
  const AppNavigationDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

const appNavigationDestinations = <AppNavigationDestination>[
  AppNavigationDestination(
    path: AppRoutes.home,
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    builder: _buildHomeScreen,
  ),
  AppNavigationDestination(
    path: AppRoutes.posts,
    label: 'Posts',
    icon: Icons.article_outlined,
    selectedIcon: Icons.article,
    builder: _buildPostsScreen,
  ),
  AppNavigationDestination(
    path: AppRoutes.about,
    label: 'About',
    icon: Icons.info_outline,
    selectedIcon: Icons.info,
    builder: _buildAboutScreen,
  ),
];

Widget _buildHomeScreen(BuildContext context) => const HomeScreen();

Widget _buildPostsScreen(BuildContext context) => const PostsScreen();

Widget _buildAboutScreen(BuildContext context) => const AboutScreen();

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
      for (final destination in appNavigationDestinations)
        GoRoute(
          path: destination.path,
          pageBuilder: (context, state) =>
              _transitionPage(state, destination.builder(context)),
        ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) =>
            _transitionPage(state, const AuthScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) =>
            _transitionPage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _transitionPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.postDetails,
        pageBuilder: (context, state) {
          final postId = int.tryParse(state.pathParameters['postId']!);
          if (postId == null || postId <= 0) {
            return _transitionPage(
              state,
              const Scaffold(body: Center(child: Text('Invalid post ID.'))),
            );
          }
          return _transitionPage(state, PostDetailsScreen(postId: postId));
        },
      ),
    ],
  );
}

CustomTransitionPage<void> _transitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final transition = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: transition,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(transition),
          child: child,
        ),
      );
    },
  );
}
