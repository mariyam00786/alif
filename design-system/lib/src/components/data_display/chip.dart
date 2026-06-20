import 'package:flutter/material.dart';

/// Chip widget for filters and tags
class Chip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final bool selected;

  const Chip({
    required this.label,
    this.onDeleted,
    this.selected = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement chip widget
    return const Text('Chip');
  }
}
