import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../components/portal_ui.dart';
import '../../services/teacher_api_service.dart';
import 'teacher_data.dart';

/// Batch analytics for a teacher (FRD §4.3.3).
///
/// Batch-wise completion rates, top performers, areas needing improvement and
/// a comparative view across the teacher's batches.
class TeacherAnalyticsScreen extends StatefulWidget {
  final bool isMalayalam;
  final List<TeacherBatch> batches;
  final List<TeacherStudent> students;

  const TeacherAnalyticsScreen({
    super.key,
    required this.isMalayalam,
    required this.batches,
    required this.students,
  });

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  int _batchIndex = 0;
  final Map<String, TeacherBatchAnalytics> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  /// Fetches live analytics for the selected batch (no-op in demo mode).
  Future<void> _loadAnalytics() async {
    if (widget.batches.isEmpty) return;
    final batch = widget.batches[_batchIndex];
    if (_analytics.containsKey(batch.id)) return;
    final data = await TeacherApiService.fetchBatchAnalytics(batch.id);
    if (!mounted || data == null) return;
    setState(() => _analytics[batch.id] = data);
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;
    final batch = widget.batches.isEmpty ? null : widget.batches[_batchIndex];

    // Top performers: prefer the live backend payload (FRD §4.3.3); fall back
    // to the local students list so the section is never empty.
    final live = batch == null ? null : _analytics[batch.id];
    final batchStudents = batch == null
        ? <TeacherStudent>[]
        : (widget.students.where((s) => s.batchId == batch.id).toList()
            ..sort((a, b) => b.weekPct.compareTo(a.weekPct)));
    final localTop = batchStudents.take(3).toList();
    final topPerformers = (live != null && live.topPerformers.isNotEmpty)
        ? live.topPerformers
        : const <TeacherPerformer>[];

    // Areas needing improvement = lowest category averages (live when available).
    final sortedAreas = (live != null && live.areasToImprove.isNotEmpty)
        ? ([...live.areasToImprove]..sort((a, b) => a.pct.compareTo(b.pct)))
        : ([...TeacherData.batchCategories]
            ..sort((a, b) => a.pct.compareTo(b.pct)));
    // Only show categories that genuinely need attention (below 60%), capped at 3.
    // Fall back to the three lowest so the section is never empty.
    final lowAreas = sortedAreas.where((a) => a.pct < 60).take(3).toList();
    final areas = lowAreas.isNotEmpty ? lowAreas : sortedAreas.take(3).toList();

    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'വിശകലനം' : 'Analytics',
            subtitle: isMalayalam
                ? 'ബാച്ച് പ്രകടനവും താരതമ്യവും'
                : 'Batch performance & comparison',
            icon: Icons.insights_rounded,
          ),
          Expanded(
            child: batch == null
                ? EmptyState(
                    icon: Icons.insights_rounded,
                    title: isMalayalam ? 'ബാച്ചുകൾ ഇല്ല' : 'No batches',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      // Batch selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(widget.batches.length, (i) {
                            final b = widget.batches[i];
                            final selected = i == _batchIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _batchIndex = i);
                                  _loadAnalytics();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected ? kGreen : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? kGreen : kBorder,
                                    ),
                                  ),
                                  child: Text(
                                    isMalayalam ? b.nameMl : b.name,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : kBody,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Completion rate cards
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              icon: Icons.groups_rounded,
                              value: '${batch.studentCount}',
                              label: isMalayalam ? 'വിദ്യാർഥികൾ' : 'Students',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              icon: Icons.bolt_rounded,
                              value: '${batch.activeToday}',
                              label: isMalayalam ? 'ഇന്ന് സജീവം' : 'Active',
                              tint: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              icon: Icons.percent_rounded,
                              value: '${batch.avgCompletion}%',
                              label: isMalayalam ? 'പൂർത്തീകരണം' : 'Completion',
                              tint: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Top performers
                      SectionLabel(
                        isMalayalam ? 'മികച്ച പ്രകടനം' : 'Top performers',
                        icon: Icons.military_tech_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (topPerformers.isEmpty && localTop.isEmpty)
                        SoftCard(
                          child: Text(
                            isMalayalam ? 'ഡാറ്റ ഇല്ല' : 'No data',
                            style: const TextStyle(color: kMuted),
                          ),
                        )
                      else if (topPerformers.isNotEmpty)
                        ...topPerformers.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LivePerformerRow(
                              rank: e.key + 1,
                              performer: e.value,
                              isMalayalam: isMalayalam,
                            ),
                          ),
                        )
                      else
                        ...localTop.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PerformerRow(
                              rank: e.key + 1,
                              student: e.value,
                              isMalayalam: isMalayalam,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Areas needing improvement
                      SectionLabel(
                        isMalayalam
                            ? 'മെച്ചപ്പെടേണ്ട മേഖലകൾ'
                            : 'Areas to improve',
                        icon: Icons.trending_down_rounded,
                      ),
                      const SizedBox(height: 10),
                      ...areas.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AreaRow(
                            category: c,
                            isMalayalam: isMalayalam,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Comparative analysis across batches (FRD §4.3.3) —
                      // live bar chart when available, fallback to the local
                      // _ComparisonRow list otherwise.
                      SectionLabel(
                        isMalayalam ? 'ബാച്ച് താരതമ്യം' : 'Batch comparison',
                        icon: Icons.bar_chart_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (live != null && live.crossBatch.isNotEmpty)
                        _CrossBatchBarCard(
                          points: live.crossBatch,
                          selectedBatchId: batch.id,
                          isMalayalam: isMalayalam,
                        )
                      else
                        SoftCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                isMalayalam
                                    ? 'ട്രെൻഡ് ലഭ്യമല്ല'
                                    : 'No trend data yet',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // 4-week completion trend rendered as a fl_chart LineChart (FRD §4.3.3).
                      // The backend returns the most-recent week first; the chart shows it left →
                      // right from oldest to newest.
                      SectionLabel(
                        isMalayalam ? 'ബാച്ച് പൂർത്തീകരണം' : 'Completion trend',
                        icon: Icons.trending_up_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (live != null && live.weeklyTrend.isNotEmpty)
                        _WeeklyTrendCard(
                          trend: live.weeklyTrend,
                          isMalayalam: isMalayalam,
                        )
                      else
                        SoftCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                isMalayalam
                                    ? 'ട്രെൻഡ് ലഭ്യമല്ല'
                                    : 'No trend data yet',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PerformerRow extends StatelessWidget {
  final int rank;
  final TeacherStudent student;
  final bool isMalayalam;

  const _PerformerRow({
    required this.rank,
    required this.student,
    required this.isMalayalam,
  });

  @override
  Widget build(BuildContext context) {
    const medals = [Color(0xFFFFA000), Color(0xFF9CA3AF), Color(0xFFB45309)];
    final medal = rank <= 3 ? medals[rank - 1] : kMuted;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: medal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: medal,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMalayalam ? student.nameMl : student.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kHeading,
              ),
            ),
          ),
          Text(
            '${student.weekPct}%',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  final CategoryScore category;
  final bool isMalayalam;

  const _AreaRow({required this.category, required this.isMalayalam});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(category.icon, color: category.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? category.titleMl : category.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: kHeading,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: category.pct / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(category.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${category.pct}%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}


class _LivePerformerRow extends StatelessWidget {
  final int rank;
  final TeacherPerformer performer;
  final bool isMalayalam;

  const _LivePerformerRow({
    required this.rank,
    required this.performer,
    required this.isMalayalam,
  });

  @override
  Widget build(BuildContext context) {
    const medals = [Color(0xFFFFA000), Color(0xFF9CA3AF), Color(0xFFB45309)];
    final medal = rank <= 3 ? medals[rank - 1] : kMuted;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: medal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: medal,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMalayalam ? performer.nameMl : performer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kHeading,
              ),
            ),
          ),
          Text(
            '${performer.pct}%',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// 4-week completion trend rendered as a fl_chart LineChart (FRD §4.3.3).
/// The backend returns the most-recent week first; the chart shows it left →
/// right from oldest to newest.
class _WeeklyTrendCard extends StatelessWidget {
  final List<TeacherWeekTrend> trend;
  final bool isMalayalam;

  const _WeeklyTrendCard({required this.trend, required this.isMalayalam});

  @override
  Widget build(BuildContext context) {
    // Oldest → newest for left-to-right reading.
    final ordered = [...trend]
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    final spots = <FlSpot>[];
    for (var i = 0; i < ordered.length; i++) {
      spots.add(FlSpot(i.toDouble(), ordered[i].completionPct.toDouble()));
    }
    final maxY = 100.0;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMalayalam ? 'പൂർത്തീകരണം %' : 'Completion %',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kBody,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: _trendGridLine,
                ),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: _trendBottomTitle,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 25,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    color: kGreen,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: kGreen.withValues(alpha: 0.12),
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Bottom-axis label for the 4-week trend chart ("W1".."W4", oldest→newest).
/// Top-level so it can be used as a const tear-off across all chart widgets.
Widget _trendBottomTitle(double value, TitleMeta meta) {
  final idx = value.round();
  if (idx < 1 || idx > 4) return const SizedBox.shrink();
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(
      'W$idx',
      style: const TextStyle(
        fontSize: 11,
        color: kMuted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Hairline horizontal grid line shared by the trend + cross-batch charts.
/// Top-level so it can be used as a const tear-off across all chart widgets.
FlLine _trendGridLine(double value) =>
    FlLine(color: const Color(0xFFEFF1F3), strokeWidth: 1);
/// Cross-batch comparison rendered as a fl_chart vertical BarChart
/// (FRD §4.3.3). The selected batch is highlighted in teal; others use a
/// muted slate.
class _CrossBatchBarCard extends StatelessWidget {
  final List<TeacherCrossBatchPoint> points;
  final String? selectedBatchId;
  final bool isMalayalam;

  const _CrossBatchBarCard({
    required this.points,
    required this.selectedBatchId,
    required this.isMalayalam,
  });

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final selected = p.id == selectedBatchId;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: p.avgCompletion.toDouble(),
              color: selected ? kGreen : const Color(0xFFCBD5E1),
              width: 22,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: const Color(0xFFEFF1F3),
              ),
            ),
          ],
        ),
      );
    }

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMalayalam ? 'ശരാശരി പൂർത്തീകരണം %' : 'Avg completion %',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kBody,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: _trendGridLine,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _truncateBatchName(points[idx].nameMl),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: points[idx].id == selectedBatchId
                                    ? kGreen
                                    : kMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 25,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: bars,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      final p = points[group.x];
                      return BarTooltipItem(
                        '${p.avgCompletion}%\n${p.studentCount} students',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _truncateBatchName(String s) =>
      s.length > 8 ? '${s.substring(0, 7)}…' : s;
}
