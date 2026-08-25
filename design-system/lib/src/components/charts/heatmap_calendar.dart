import 'package:flutter/material.dart';

/// Heatmap calendar for showing activity contribution
class HeatmapCalendar extends StatelessWidget {
  final Map<DateTime, int> data;
  final Function(DateTime)? onDateTap;

  const HeatmapCalendar({
    required this.data,
    this.onDateTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement GitHub-style activity heatmap calendar
    return const Text('Heatmap Calendar');
  }
}
