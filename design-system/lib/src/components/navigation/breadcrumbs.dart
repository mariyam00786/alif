import 'package:flutter/material.dart';

/// Breadcrumbs widget for navigation hierarchy
class Breadcrumbs extends StatelessWidget {
  final List<String> items;
  final Function(int)? onItemTap;

  const Breadcrumbs({
    required this.items,
    this.onItemTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement breadcrumbs widget
    return const Text('Breadcrumbs');
  }
}
