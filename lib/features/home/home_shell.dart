import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_navigation.dart';
import '../devices/devices_screen.dart';
import '../routes/route_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Bottom-nav shell holding the four main tabs. The selected tab lives in
/// [homeTabProvider] so screens like Home can switch to Routes programmatically.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = [
    HomeScreen(),
    DevicesScreen(),
    RouteScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.watch_outlined),
              selectedIcon: Icon(Icons.watch),
              label: 'Devices'),
          NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Routes'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
