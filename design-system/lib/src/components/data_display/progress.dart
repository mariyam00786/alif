import 'package:flutter/material.dart';

/// Progress indicator widget (linear or circular)
class Progress extends StatelessWidget {
  final double value;
  final double? size;
  final bool isLinear;

  const Progress({
    required this.value,
    this.size,
    this.isLinear = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement progress indicator
    return isLinear
        ? LinearProgressIndicator(value: value)
        : CircularProgressIndicator(value: value);
  }
}
