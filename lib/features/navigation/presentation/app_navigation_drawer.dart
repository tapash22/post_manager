import 'package:flutter/material.dart';

import '../../posts/presentation/posts_screen.dart';
import 'home_screen.dart';

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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) =>
                index == 0 ? const HomeScreen() : const PostsScreen(),
          ),
        );
      },
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text('Post Manager'),
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
