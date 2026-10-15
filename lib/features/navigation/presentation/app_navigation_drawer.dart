import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';

class AppNavigationDrawer extends StatelessWidget {
  final bool postsSelected;

  const AppNavigationDrawer({
    super.key,
    required this.postsSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: postsSelected ? 1 : 0,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        context.go(index == 0 ? AppRoutes.home : AppRoutes.posts);
      },
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            children: [
              Icon(Icons.dashboard_rounded),
              SizedBox(width: 12),
              Text('Post Manager'),
            ],
          ),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: Text('Posts'),
        ),
      ],
    );
  }
}
