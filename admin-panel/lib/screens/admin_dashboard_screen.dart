import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/app_models.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.state});

  final AdminAppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalStudents = state.students.length;
    final activeToday = state.students
        .where((item) => item.status == RecordStatus.active)
        .length;
    final activitiesCompletedToday = state.activities
        .where((item) => item.isActive)
        .length;

    final topPerformer = state.students.isEmpty
        ? '-'
        : (state.students.toList()..sort((a, b) => b.score.compareTo(a.score)))
              .first
              .name;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            LayoutBuilder(
              builder: (context, constraints) {
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin overview for students, daily activities, and performance insights.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                );
                return titleBlock;
              },
            ),
            const SizedBox(height: 12),

            // Metrics Grid - always 2 columns (4 on wide desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 900 ? 4 : 2;
                final isCompact = width < 380;
                final spacing = isCompact ? 10.0 : 14.0;

                final cards = _metricCards(
                  totalStudents,
                  activeToday,
                  activitiesCompletedToday,
                  topPerformer,
                );

                final cardWidth =
                    (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: cardWidth,
                        child: StatCard(
                          icon: card.icon,
                          iconColor: card.iconColor,
                          iconBackground: card.iconBackground,
                          label: card.label,
                          malayalamLabel: card.malayalamLabel,
                          value: card.value,
                          description: card.description,
                          statusColor: card.statusColor,
                          compact: isCompact,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Reports Section
            _buildReportsSection(context, theme),
          ],
        ),
      ),
    );
  }

  List<_MetricCardData> _metricCards(
    int totalStudents,
    int activeToday,
    int activitiesCompletedToday,
    String topPerformer,
  ) {
    return [
      _MetricCardData(
        icon: Icons.people_alt_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBackground: const Color(0xFFEDE9FE),
        label: 'Total Students',
        malayalamLabel: 'മൊത്തം വിദ്യാർത്ഥികൾ',
        value: '$totalStudents',
        description: 'registered students',
        statusColor: const Color(0xFF6B7280),
      ),
      _MetricCardData(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF16A34A),
        iconBackground: const Color(0xFFDCFCE7),
        label: 'Active Today',
        malayalamLabel: 'ഇന്ന് സജീവം',
        value: '$activeToday',
        description: 'status marked active',
        statusColor: const Color(0xFF16A34A),
      ),
      _MetricCardData(
        icon: Icons.assignment_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBackground: const Color(0xFFDBEAFE),
        label: 'Activities Live',
        malayalamLabel: 'സജീവ പ്രവർത്തനങ്ങൾ',
        value: '$activitiesCompletedToday',
        description: 'active configurations',
        statusColor: const Color(0xFF2563EB),
      ),
      _MetricCardData(
        icon: Icons.star_rounded,
        iconColor: const Color(0xFFEA580C),
        iconBackground: const Color(0xFFFFEDD5),
        label: 'Top Performer',
        malayalamLabel: 'മികച്ച പ്രകടനം',
        value: topPerformer,
        description: 'highest scorer',
        statusColor: const Color(0xFF6B7280),
      ),
    ];
  }

  Widget _buildReportsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operational Highlights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'പ്രവർത്തന സംഗ്രഹം',
          style: GoogleFonts.notoSansMalayalam(
            textStyle: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.reports.length,
              itemBuilder: (context, index) {
                final report = state.reports[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.trendLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF6B7280),
                                fontSize: 11,
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
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              report.change,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.malayalamLabel,
    required this.value,
    required this.description,
    required this.statusColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String malayalamLabel;
  final String value;
  final String description;
  final Color statusColor;
}

/// Reusable StatCard widget that hugs its content with a pastel icon chip,
/// clear typography hierarchy and a colored status line.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.malayalamLabel,
    required this.value,
    required this.description,
    required this.statusColor,
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String malayalamLabel;
  final String value;
  final String description;
  final Color statusColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastel icon chip
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            // Label - medium grey
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: compact ? 13 : 14,
              ),
            ),
            Text(
              malayalamLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansMalayalam(
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey[400],
                  fontSize: compact ? 9 : 10,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Big number + status text. Numeric values stay large with an
            // inline status; longer text values (e.g. names) shrink and wrap
            // so they remain fully visible inside the card.
            _buildValueBlock(theme),
          ],
        ),
      ),
    );
  }

  bool get _isShortValue {
    // Treat purely numeric / short values (<= 4 chars) as "stat numbers".
    final numeric = double.tryParse(value.replaceAll('%', '')) != null;
    return numeric || value.length <= 4;
  }

  Widget _buildValueBlock(ThemeData theme) {
    if (_isShortValue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              fontSize: compact ? 24 : 28,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 11,
              height: 1.15,
            ),
          ),
        ],
      );
    }

    // Text value (e.g. a name): full width, wraps to two lines, smaller font.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            fontSize: compact ? 15 : 17,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: compact ? 10 : 11,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
