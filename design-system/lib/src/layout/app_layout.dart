import 'package:flutter/material.dart';

/// App layout with top or bottom navigation
class AppLayout extends StatelessWidget {
  final List<String> navigationItems;
  final Widget content;
  final int activeIndex;
  final Function(int)? onNavigationTap;
  final bool isBottomNav;

  const AppLayout({
    required this.navigationItems,
    required this.content,
    this.activeIndex = 0,
    this.onNavigationTap,
    this.isBottomNav = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement app layout with responsive navigation
    return Scaffold(
      body: content,
      bottomNavigationBar: isBottomNav
          ? BottomNavigationBar(
              items: navigationItems
                  .map((item) => BottomNavigationBarItem(label: item, icon: const Icon(Icons.home)))
                  .toList(),
              currentIndex: activeIndex,
              onTap: onNavigationTap,
            )
          : null,
    );
  }
}
