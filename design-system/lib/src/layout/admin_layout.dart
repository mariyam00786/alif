import 'package:flutter/material.dart';

/// Admin layout with sidebar navigation
class AdminLayout extends StatelessWidget {
  final List<String> navigationItems;
  final Widget content;
  final int activeIndex;
  final Function(int)? onNavigationTap;

  const AdminLayout({
    required this.navigationItems,
    required this.content,
    this.activeIndex = 0,
    this.onNavigationTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement admin layout with sidebar and top bar
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: Colors.grey[50],
            child: Column(
              children: [
                // Logo
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Alif School'),
                ),
                // Navigation menu items
                Expanded(
                  child: ListView.builder(
                    itemCount: navigationItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(navigationItems[index]),
                        selected: index == activeIndex,
                        onTap: () => onNavigationTap?.call(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }
}
