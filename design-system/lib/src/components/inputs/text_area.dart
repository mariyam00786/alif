import 'package:flutter/material.dart';

/// Text area (multi-line input)
class TextArea extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool required;

  const TextArea({
    this.label,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.minLines = 3,
    this.maxLines = 5,
    this.maxLength,
    this.required = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement text area with proper styling
    return const TextField();
  }
}
