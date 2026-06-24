import 'package:flutter/material.dart';

import '../model/app_models.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.state});

  final AdminAppState state;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;
    final totalStudents = state.students.length;
    final activeToday = state.students
        .where((item) => item.status == RecordStatus.active)
        .length;
    final activitiesLive = state.activities
        .where((item) => item.isActive)
        .length;

    final topPerformer = state.students.isEmpty
        ? '-'
        : (state.students.toList()..sort((a, b) => b.score.compareTo(a.score)))
              .first
              .name;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 20,
          isCompact ? 12 : 20,
          isCompact ? 12 : 20,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              totalStudents: totalStudents,
              activeToday: activeToday,
              compact: isCompact,
            ),
            SizedBox(height: isCompact ? 14 : 20),
            _KpiBand(
              metrics: _metricData(
                totalStudents,
                activeToday,
                activitiesLive,
                topPerformer,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 24),
            _ReportsPanel(reports: state.reports),
          ],
        ),
      ),
    );
  }

  List<_Metric> _metricData(
    int totalStudents,
    int activeToday,
    int activitiesLive,
    String topPerformer,
  ) {
    return [
      _Metric(
        icon: Icons.people_alt_rounded,
        accent: const Color(0xFF7C3AED),
        label: 'Total Students',
        value: '$totalStudents',
        caption: 'Registered students',
      ),
      _Metric(
        icon: Icons.check_circle_rounded,
        accent: const Color(0xFF16A34A),
        label: 'Active Today',
        value: '$activeToday',
        caption: 'Marked active',
      ),
      _Metric(
        icon: Icons.assignment_rounded,
        accent: const Color(0xFF2563EB),
        label: 'Activities Live',
        value: '$activitiesLive',
        caption: 'Active configurations',
      ),
      _Metric(
        icon: Icons.star_rounded,
        accent: const Color(0xFFEA580C),
        label: 'Top Performer',
        value: topPerformer,
        caption: 'Highest scorer',
      ),
    ];
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.totalStudents,
    required this.activeToday,
    this.compact = false,
  });

  final int totalStudents;
  final int activeToday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF115E59), Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        child: Stack(
          children: [
            // Mosque watermark illustration (top-right).
            Positioned(
              right: compact ? -20 : -24,
              top: compact ? -18 : -22,
              child: Icon(
                Icons.mosque_rounded,
                size: compact ? 124 : 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            // Crescent moon + stars, matching the student app hero.
            Positioned(
              right: compact ? 24 : 30,
              top: compact ? 18 : 22,
              child: Icon(
                Icons.nightlight_round,
                size: compact ? 17 : 20,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const Positioned(
              right: 70,
              top: 30,
              child: _Star(size: 4),
            ),
            const Positioned(
              right: 58,
              top: 52,
              child: _Star(size: 3),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 22,
                compact ? 16 : 22,
                compact ? 16 : 22,
                compact ? 16 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assalamu alaikum',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Text(
                    'Admin Dashboard',
                    style: (compact
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    'Daily overview of students, activities and performance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  Row(
                    children: [
                      _HeroChip(
                        icon: Icons.people_alt_rounded,
                        label: '$totalStudents students',
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      _HeroChip(
                        icon: Icons.check_circle_rounded,
                        label: '$activeToday active today',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single flat KPI presentation — no elevated cards. KPIs sit inside one
/// bordered surface separated by hairline dividers, like modern dashboards.
class _KpiBand extends StatelessWidget {
  const _KpiBand({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? metrics.length
          : constraints.maxWidth >= 360
            ? 2
            : 1;

        final rows = <List<int>>[];
        for (var i = 0; i < metrics.length; i += columns) {
          rows.add([
            for (var j = i; j < i + columns && j < metrics.length; j++) j,
          ]);
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              for (var r = 0; r < rows.length; r++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < columns; c++)
                        Expanded(
                          child: c < rows[r].length
                              ? _KpiCell(
                                  metric: metrics[rows[r][c]],
                                  showRightDivider: c != columns - 1,
                                  showBottomDivider: r != rows.length - 1,
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.metric,
    required this.showRightDivider,
    required this.showBottomDivider,
  });

  final _Metric metric;
  final bool showRightDivider;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const divider = Color(0xFFE5E7EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          right: showRightDivider
              ? const BorderSide(color: divider)
              : BorderSide.none,
          bottom: showBottomDivider
              ? const BorderSide(color: divider)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: metric.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(metric.icon, color: metric.accent, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat bordered panel listing operational report highlights as clean rows
/// separated by hairline dividers.
class _ReportsPanel extends StatelessWidget {
  const _ReportsPanel({required this.reports});

  final List<ReportSnapshot> reports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operational Highlights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Key trends across participation and performance.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < reports.length; i++)
                _ReportRow(
                  report: reports[i],
                  showDivider: i < reports.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.showDivider});

  final ReportSnapshot report;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: Color(0xFFF1F4F1))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.trending_up_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  report.trendLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                report.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.change,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String caption;
}
