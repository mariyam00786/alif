import 'package:flutter/material.dart';

/// Bottom sheet widget
class BottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool dismissible;

  const BottomSheet({
    this.title,
    required this.child,
    this.dismissible = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement bottom sheet
    return const Text('Bottom Sheet');
  }
}
