import 'package:flutter/material.dart';

/// App navigation widget
class AppNavigation extends StatelessWidget {
  final List<String> items;
  final int activeIndex;
  final Function(int)? onItemTap;
  final bool isBottomNav;

  const AppNavigation({
    required this.items,
    this.activeIndex = 0,
    this.onItemTap,
    this.isBottomNav = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement app navigation (bottom nav or top nav)
    return const Text('App Navigation');
  }
}
