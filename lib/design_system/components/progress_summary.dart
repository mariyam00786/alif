import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Progress summary showing student daily performance
/// Displays: Date, Total Marks, Completion %, Rank
class AlifProgressSummary extends StatelessWidget {
  final String date;
  final int totalMarks;
  final double completionPercentage;
  final int currentRank;
  final int totalStudents;
  final int activitiesCompleted;
  final int totalActivities;
  final String? trend;
  final bool isMalayalam;

  const AlifProgressSummary({
    Key? key,
    required this.date,
    required this.totalMarks,
    required this.completionPercentage,
    required this.currentRank,
    required this.totalStudents,
    required this.activitiesCompleted,
    required this.totalActivities,
    this.trend,
    this.isMalayalam = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.white,
        border: Border.all(color: ColorPalette.neutral300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(SpacingScale.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date and Trend
          _buildHeader(),
          SizedBox(height: SpacingScale.lg),

          // Main metrics grid
          _buildMetricsGrid(),
          SizedBox(height: SpacingScale.lg),

          // Completion bar
          _buildCompletionBar(),
          SizedBox(height: SpacingScale.md),

          // Activity progress
          _buildActivityProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          date,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorPalette.textPrimary,
          ),
        ),
        if (trend != null) ...[
          _buildTrendBadge(),
        ],
      ],
    );
  }

  Widget _buildTrendBadge() {
    Color trendColor;
    IconData trendIcon;

    if (trend == 'improving') {
      trendColor = ColorPalette.ratingExcellent;
      trendIcon = Icons.trending_up;
    } else if (trend == 'declining') {
      trendColor = ColorPalette.ratingNeedsImprovement;
      trendIcon = Icons.trending_down;
    } else {
      trendColor = ColorPalette.ratingSatisfactory;
      trendIcon = Icons.trending_flat;
    }

    return Container(
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: SpacingScale.sm,
        vertical: SpacingScale.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 14, color: trendColor),
          SizedBox(width: SpacingScale.xs),
          Text(
            trend ?? '',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: SpacingScale.md,
      crossAxisSpacing: SpacingScale.md,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          label: isMalayalam ? 'ആകെ മാർക്കുകൾ' : 'Total Marks',
          value: '$totalMarks',
          icon: Icons.star,
          color: ColorPalette.primaryDark,
        ),
        _buildMetricCard(
          label: isMalayalam ? 'സമ്പൂർണ്ണതാ' : 'Completion',
          value: '${completionPercentage.toInt()}%',
          icon: Icons.check_circle,
          color: ColorPalette.ratingExcellent,
        ),
        _buildMetricCard(
          label: isMalayalam ? 'റാങ്ക്' : 'Rank',
          value: '#$currentRank',
          subtitle: 'of $totalStudents',
          icon: Icons.emoji_events,
          color: ColorPalette.secondary,
        ),
        _buildMetricCard(
          label: isMalayalam ? 'പ്രവർത്തനങ്ങൾ' : 'Activities',
          value: '$activitiesCompleted',
          subtitle: 'of $totalActivities',
          icon: Icons.task_alt,
          color: ColorPalette.primaryLight,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(SpacingScale.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorPalette.textPrimary,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: ColorPalette.neutral600,
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: ColorPalette.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMalayalam ? 'സമ്പൂർണ്ണതാ ബാർ' : 'Completion Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
            ),
            Text(
              '${completionPercentage.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ColorPalette.primaryDark,
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingScale.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completionPercentage / 100,
            minHeight: 8,
            backgroundColor: ColorPalette.neutral200,
            valueColor: AlwaysStoppedAnimation(
              completionPercentage >= 75
                  ? ColorPalette.ratingExcellent
                  : (completionPercentage >= 50
                      ? ColorPalette.ratingSatisfactory
                      : ColorPalette.ratingNeedsImprovement),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isMalayalam ? 'പ്രവർത്തനങ്ങളുടെ പുരോഗതി' : 'Activities Progress',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorPalette.textPrimary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ColorPalette.primaryDark.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.sm,
            vertical: SpacingScale.xs,
          ),
          child: Text(
            '$activitiesCompleted/$totalActivities',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ColorPalette.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact progress card for dashboard/summary views
class AlifCompactProgressCard extends StatelessWidget {
  final String title;
  final int value;
  final int maxValue;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const AlifCompactProgressCard({
    Key? key,
    required this.title,
    required this.value,
    required this.maxValue,
    this.color,
    this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue * 100).clamp(0, 100);
    final progressColor = color ??
        (percentage >= 75
            ? ColorPalette.ratingExcellent
            : (percentage >= 50
                ? ColorPalette.ratingSatisfactory
                : ColorPalette.ratingNeedsImprovement));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.white,
          border: Border.all(color: ColorPalette.neutral300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(SpacingScale.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(icon, size: 16, color: progressColor),
              ],
            ),
            SizedBox(height: SpacingScale.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$value/$maxValue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingScale.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 6,
                backgroundColor: ColorPalette.neutral200,
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Milestone/achievement tracker
class AlifMilestoneTracker extends StatelessWidget {
  final List<String> milestones;
  final int completedCount;
  final bool showDetails;

  const AlifMilestoneTracker({
    Key? key,
    required this.milestones,
    required this.completedCount,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.white,
        border: Border.all(color: ColorPalette.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(SpacingScale.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Milestones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          SizedBox(height: SpacingScale.md),
          Column(
            children: [
              for (int i = 0; i < milestones.length; i++) ...[
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i < completedCount
                            ? ColorPalette.ratingExcellent
                            : ColorPalette.neutral200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          i < completedCount ? Icons.check : Icons.pending,
                          size: 12,
                          color: i < completedCount
                              ? ColorPalette.white
                              : ColorPalette.neutral600,
                        ),
                      ),
                    ),
                    SizedBox(width: SpacingScale.md),
                    Expanded(
                      child: Text(
                        milestones[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: i < completedCount
                              ? ColorPalette.textPrimary
                              : ColorPalette.neutral600,
                          decoration: i < completedCount
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < milestones.length - 1)
                  SizedBox(height: SpacingScale.md),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
