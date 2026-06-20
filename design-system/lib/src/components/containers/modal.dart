import 'package:flutter/material.dart';

/// Modal/Dialog widget
class Modal extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool dismissible;

  const Modal({
    required this.title,
    required this.content,
    this.actions,
    this.dismissible = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement modal dialog
    return const Text('Modal');
  }
}
