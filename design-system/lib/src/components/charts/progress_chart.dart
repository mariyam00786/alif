import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Progress chart for visualizing student progress over time
class ProgressChart extends StatelessWidget {
  final List<FlSpot> data;
  final String title;
  final String? unit;

  const ProgressChart({
    required this.data,
    required this.title,
    this.unit,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement progress chart with line, bar, or area chart
    return const Text('Progress Chart');
  }
}
