import 'package:flutter/material.dart';

/// Empty state widget for no content
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement empty state widget
    return const Text('Empty State');
  }
}
