import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';

class AppNavigationDrawer extends StatelessWidget {
  static const _drawerCloseDuration = Duration(milliseconds: 250);

  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final currentPath = router.state.uri.path;
    final selectedIndex = appNavigationDestinations.indexWhere(
      (destination) => destination.path == currentPath,
    );

    return NavigationDrawer(
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      onDestinationSelected: (index) {
        final destination = appNavigationDestinations[index];
        // .pop() removes the current drawer route from the navigation stack.
        // This does not navigate to Home or Posts. It only closes the drawer.
        Navigator.of(context).pop();

        //Purpose: Delays route navigation until the drawer has time to close.

        // - Future<void>: Represents an asynchronous operation that doesn't return a value.
        // - delayed(): Executes a callback after a specified duration.
        // - _drawerCloseDuration: Your configured delay.
        // - () {}: Callback executed after the delay.
        Future<void>.delayed(_drawerCloseDuration, () {
          router.go(destination.path);
        });
      },
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            children: [
              Icon(Icons.dashboard_rounded),
              SizedBox(width: 12),
              Text('Post Manager'),
            ],
          ),
        ),
        for (final destination in appNavigationDestinations)
          NavigationDrawerDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}
