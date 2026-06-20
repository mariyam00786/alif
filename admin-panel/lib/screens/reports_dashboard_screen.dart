import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

/// Reports Dashboard (FRP Sec 4.8).
///
/// Read-only operational insights: participation and score metrics plus the
/// available report views (daily / weekly / monthly, by student / batch /
/// teacher). No export buttons or SLA/vanity feeds (out of FRP scope).
class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key, required this.state});

  final AdminAppState state;

  static const List<(IconData, String, String)> _reportViews = [
    (
      Icons.event_available_outlined,
      'Daily report',
      'Per-day activity completion and points earned.',
    ),
    (
      Icons.calendar_view_week_outlined,
      'Weekly report',
      'Weekly participation and streak changes.',
    ),
    (
      Icons.calendar_month_outlined,
      'Monthly report',
      'Monthly progress summary and averages.',
    ),
    (
      Icons.person_outline,
      'Student report',
      'Individual scores, streaks, and activity history.',
    ),
    (
      Icons.class_outlined,
      'Batch report',
      'Batch-level participation and average scores.',
    ),
    (
      Icons.school_outlined,
      'Teacher report',
      'Activity logging and class coverage per teacher.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminPageFrame(
      title: 'Reports Dashboard',
      subtitle: 'Track participation, scores, and progress across the school.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 760 ? 4 : 2;
            final cardHeight = width < 600 ? 96.0 : 100.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.reports.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: cardHeight,
              ),
              itemBuilder: (context, index) {
                final report = state.reports[index];
                return MetricCard(
                  label: report.title,
                  value: report.value,
                  supportingText: '${report.change} · ${report.trendLabel}',
                  tint: theme.colorScheme.primary,
                );
              },
            );
          },
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report views', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Open a view to drill into the underlying data.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 720 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reportViews.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 80,
                      ),
                      itemBuilder: (context, index) {
                        final view = _reportViews[index];
                        return _ReportViewTile(
                          icon: view.$1,
                          title: view.$2,
                          description: view.$3,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportViewTile extends StatelessWidget {
  const _ReportViewTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
