import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/admin_spacing.dart';

class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.titleWidget,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  /// Optional custom header widget. When provided, it replaces the default
  /// title + subtitle text block (used by the Dashboard hero card so it keeps
  /// its visuals while sharing the frame's spacing and list rhythm).
  final Widget? titleWidget;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 820;
        final contentWidth = constraints.maxWidth > 920
            ? 820.0
            : constraints.maxWidth;
        final resolvedActions = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: actions
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AdminSpacing.xs + 2,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: action,
                        ),
                      ),
                    )
                    .toList(),
              )
            : Wrap(
                spacing: AdminSpacing.md,
                runSpacing: AdminSpacing.md,
                children: actions,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AdminSpacing.xs,
                vertical: isCompact ? 2 : AdminSpacing.xs + 2,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: AdminSpacing.md + 2,
                spacing: AdminSpacing.lg,
                children: [
                  SizedBox(
                    width: contentWidth,
                    child:
                        titleWidget ??
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: AdminSpacing.xs),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                  ),
                  if (actions.isNotEmpty)
                    SizedBox(
                      width: isCompact ? contentWidth : null,
                      child: resolvedActions,
                    ),
                ],
              ),
            ),
            SizedBox(height: isCompact ? AdminSpacing.xs + 6 : AdminSpacing.lg),
            Expanded(
              child: ListView.separated(
                itemCount: children.length,
                separatorBuilder: (_, _) => SizedBox(
                  height: isCompact ? AdminSpacing.xs + 6 : AdminSpacing.md + 2,
                ),
                padding: EdgeInsets.only(
                  bottom: isCompact ? AdminSpacing.xxl * 4 : AdminSpacing.lg,
                ),
                itemBuilder: (context, index) => children[index],
              ),
            ),
          ],
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.supportingText,
    required this.tint,
    this.icon = Icons.bar_chart,
  });

  final String label;
  final String value;
  final String supportingText;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AdminSpacing.md),
              ),
              child: Icon(icon, color: tint, size: AdminSpacing.xl),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.sm),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supportingText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
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

class StatItem {
  const StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.tint,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? tint;
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 380
            ? AdminSpacing.sm
            : AdminSpacing.md;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(
                  child: _StatTile(item: items[i], paletteIndex: i),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item, required this.paletteIndex});

  final StatItem item;
  final int paletteIndex;

  static const List<List<Color>> _palette = [
    [Color(0xFF7C3AED), Color(0xFFEDE9FE)], // purple
    [Color(0xFF16A34A), Color(0xFFDCFCE7)], // green
    [Color(0xFF2563EB), Color(0xFFDBEAFE)], // blue
    [Color(0xFFEA580C), Color(0xFFFFEDD5)], // orange
    [Color(0xFFDB2777), Color(0xFFFCE7F3)], // pink
    [Color(0xFF0891B2), Color(0xFFCFFAFE)], // cyan
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pair = _palette[paletteIndex % _palette.length];
    final iconColor = item.tint ?? pair[0];
    final iconBackground = item.tint != null
        ? item.tint!.withValues(alpha: 0.12)
        : pair[1];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.xs + 6,
          vertical: AdminSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(item.icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: AdminSpacing.xs + 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item.value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  fontSize: 22,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.filterLabel,
    required this.filterValue,
    required this.filterOptions,
    required this.onFilterChanged,
    this.extraActions = const [],
  });

  final TextEditingController searchController;
  final String searchHint;
  final String filterLabel;
  final String filterValue;
  final List<String> filterOptions;
  final ValueChanged<String?> onFilterChanged;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: TextField(
                controller: searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: searchHint,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AdminSpacing.xs + 6),
            SizedBox(
              height: 40,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CompactFilterDropdown(
                      label: filterLabel,
                      value: filterValue,
                      options: filterOptions,
                      onChanged: onFilterChanged,
                    ),
                    for (final action in extraActions) ...[
                      const SizedBox(width: AdminSpacing.sm),
                      action,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact dropdown used inside [FilterBar]'s horizontal scrollable filter row.
class CompactFilterDropdown extends StatelessWidget {
  const CompactFilterDropdown({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(AdminSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: AdminSpacing.xs + 2),
          ],
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(AdminSpacing.md),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
              items: options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkflowCallout extends StatelessWidget {
  const WorkflowCallout({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
  });

  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final contentWidth = constraints.maxWidth > 780
            ? 720.0
            : constraints.maxWidth;

        return Card(
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AdminSpacing.lg,
              runSpacing: AdminSpacing.lg,
              children: [
                SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: AdminSpacing.sm),
                      Text(description, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: AdminSpacing.md + 2),
                      Container(
                        width: 64,
                        height: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.18),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: isCompact ? contentWidth : null,
                  child: Wrap(
                    spacing: AdminSpacing.md,
                    runSpacing: AdminSpacing.md,
                    children: actions,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AdminSpacing.xs + 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

void showInlineMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentMaterialBanner();

  final isError =
      message.toLowerCase().contains('could not') ||
      message.toLowerCase().contains('cannot') ||
      message.toLowerCase().contains('failed') ||
      message.toLowerCase().contains('error');
  final color = isError ? const Color(0xFFDC2626) : const Color(0xFF0F766E);

  if (isError) {
    HapticFeedback.heavyImpact();
  } else {
    HapticFeedback.selectionClick();
  }

  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: color.withValues(alpha: 0.10),
      surfaceTintColor: Colors.transparent,
      leading: Icon(
        isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
        color: color,
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: Text(
            'Dismiss',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Future<void>.delayed(const Duration(seconds: 4), () {
    if (messenger.mounted) {
      messenger.hideCurrentMaterialBanner();
    }
  });
}

Future<bool> showDeleteConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed == true;
}
