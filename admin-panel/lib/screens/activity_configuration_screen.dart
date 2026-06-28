import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';
import '../constants/admin_spacing.dart';

/// Activity Configuration (FRP Sec 4.4).
///
/// Add / edit / delete scoring activities grouped by category, with points and
/// an optional quantity flag (e.g. Quran pages). No approval-requirement field
/// (out of FRP scope).
class ActivityConfigurationScreen extends StatefulWidget {
  const ActivityConfigurationScreen({
    super.key,
    required this.activities,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<ActivityRule> activities;
  final ValueChanged<ActivityRule> onAdd;
  final ValueChanged<ActivityRule> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<ActivityConfigurationScreen> createState() =>
      _ActivityConfigurationScreenState();
}

class _ActivityConfigurationScreenState
    extends State<ActivityConfigurationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _categoryFilter = 'All categories';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final set = <String>{};
    for (final a in widget.activities) {
      if (a.category.isNotEmpty) set.add(a.category);
    }
    return set.toList()..sort();
  }

  List<ActivityRule> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return widget.activities.where((a) {
      final matchesQuery =
          query.isEmpty ||
          a.name.toLowerCase().contains(query) ||
          a.category.toLowerCase().contains(query);
      final category = a.category.isEmpty ? 'Uncategorized' : a.category;
      final matchesCategory =
          _categoryFilter == 'All categories' || category == _categoryFilter;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> _openForm({ActivityRule? existing}) async {
    final result = await showModalBottomSheet<ActivityRule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ActivityFormSheet(existing: existing, categories: _categories),
    );
    if (result == null) return;
    if (existing == null) {
      widget.onAdd(result);
      if (mounted) showInlineMessage(context, 'Activity added successfully.');
    } else {
      widget.onUpdate(result);
      if (mounted) showInlineMessage(context, 'Activity updated successfully.');
    }
  }

  Future<void> _confirmDelete(ActivityRule activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity'),
        content: Text('Remove ${activity.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDelete(activity.id);
      if (mounted) showInlineMessage(context, 'Activity removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 560;
    final filtered = _filtered;
    final grouped = <String, List<ActivityRule>>{};
    for (final a in filtered) {
      final key = a.category.isEmpty ? 'Uncategorized' : a.category;
      grouped.putIfAbsent(key, () => []).add(a);
    }
    final categoryKeys = grouped.keys.toList()..sort();

    return AdminPageFrame(
      title: 'Activity Configuration',
      subtitle: 'Define scoring activities and their points by category.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_task),
          label: const Text('Add Activity'),
        ),
      ],
      children: [
        FilterBar(
          searchController: _searchController,
          searchHint: 'Search by activity or category',
          filterLabel: 'Category',
          filterValue: _categoryFilter,
          filterOptions: ['All categories', ..._categories],
          onFilterChanged: (value) =>
              setState(() => _categoryFilter = value ?? 'All categories'),
        ),
        StatGrid(
          items: [
            StatItem(
              value: '${widget.activities.length}',
              label: 'Activities',
              icon: Icons.tune,
            ),
            StatItem(
              value: '${_categories.length}',
              label: 'Categories',
              icon: Icons.category_outlined,
            ),
            StatItem(
              value: '${widget.activities.where((a) => a.isActive).length}',
              label: 'Active',
              icon: Icons.bolt_outlined,
            ),
          ],
        ),
        const _SwipeGuideCard(),
        if (filtered.isEmpty)
          const _EmptyState()
        else
          for (final key in categoryKeys)
            _CategoryGroup(
              category: key,
              activities: grouped[key]!,
              compact: isMobile,
              onEdit: (a) => _openForm(existing: a),
              onDelete: _confirmDelete,
            ),
      ],
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.category,
    required this.activities,
    this.compact = false,
    required this.onEdit,
    required this.onDelete,
  });

  final String category;
  final List<ActivityRule> activities;
  final bool compact;
  final ValueChanged<ActivityRule> onEdit;
  final ValueChanged<ActivityRule> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? AdminSpacing.sm + 2 : AdminSpacing.md + 2,
              compact ? AdminSpacing.sm : AdminSpacing.md,
              compact ? AdminSpacing.sm + 2 : AdminSpacing.md + 2,
              compact ? AdminSpacing.xs + 2 : AdminSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: compact ? 16 : 18,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(
                  width: compact ? AdminSpacing.xs + 2 : AdminSpacing.sm,
                ),
                Expanded(
                  child: Text(
                    category,
                    style:
                        (compact
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < activities.length; i++)
            Dismissible(
              key: ValueKey('activity-${activities[i].id}'),
              direction: DismissDirection.horizontal,
              background: const _SwipeActionBackground(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: Color(0xFF0F766E),
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: const _SwipeActionBackground(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Color(0xFFDC2626),
                alignment: Alignment.centerRight,
              ),
              confirmDismiss: (direction) async {
                final activity = activities[i];
                if (direction == DismissDirection.startToEnd) {
                  onEdit(activity);
                } else {
                  onDelete(activity);
                }
                return false;
              },
              child: _ActivityTile(
                activity: activities[i],
                compact: compact,
                showDivider: i < activities.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.showDivider,
    this.compact = false,
  });

  final ActivityRule activity;
  final bool showDivider;
  final bool compact;

  String get _statusLabel => activity.isActive ? 'Active' : 'Inactive';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AdminSpacing.sm + 2 : AdminSpacing.md + 2,
        vertical: compact ? AdminSpacing.sm : AdminSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: Color(0xFFF1F4F1))
              : BorderSide.none,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = compact || constraints.maxWidth < 620;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.name,
                style:
                    (isCompact
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
              ),
            ],
          );

          final chips = Wrap(
            spacing: isCompact ? AdminSpacing.xs : AdminSpacing.xs + 2,
            runSpacing: isCompact ? 2 : AdminSpacing.xs,
            children: [
              StatusPill(
                label: '${activity.points} pts',
                color: theme.colorScheme.primary,
              ),
              if (activity.hasQuantity)
                const StatusPill(label: 'per qty', color: Color(0xFF1E293B)),
              StatusPill(
                label: _statusLabel,
                color: activity.isActive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF9E9E9E),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                SizedBox(
                  height: isCompact ? AdminSpacing.xs : AdminSpacing.xs + 2,
                ),
                Row(
                  children: [
                    Expanded(child: chips),
                    if (!compact)
                      const Padding(
                        padding: EdgeInsets.only(left: AdminSpacing.xs + 2),
                        child: _SwipeHintChip(),
                      ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: AdminSpacing.md),
              Flexible(child: chips),
              const SizedBox(width: AdminSpacing.xs + 6),
              const _SwipeHintChip(),
            ],
          );
        },
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.icon,
    required this.label,
    required this.color,
    required this.alignment,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SwipeHintChip extends StatelessWidget {
  const _SwipeHintChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF64748B)),
          SizedBox(width: 4),
          Icon(Icons.swipe_left_rounded, size: 14, color: Color(0xFF94A3B8)),
          SizedBox(width: 4),
          Text(
            'Swipe',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeGuideCard extends StatelessWidget {
  const _SwipeGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Swipe right to edit, left to delete',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 48,
          horizontal: AdminSpacing.xxl,
        ),
        child: Column(
          children: [
            Icon(
              Icons.tune,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text('No activities found', style: theme.textTheme.titleMedium),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              'Add an activity to start scoring student deeds.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit activity form sheet implementing the FRP field set.
class ActivityFormSheet extends StatefulWidget {
  const ActivityFormSheet({super.key, this.existing, required this.categories});

  final ActivityRule? existing;
  final List<String> categories;

  @override
  State<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _points;
  bool _hasQuantity = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _points = TextEditingController(text: (e?.points ?? 0).toString());
    _hasQuantity = e?.hasQuantity ?? false;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _points.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final e = widget.existing;
    final record = ActivityRule(
      id: e?.id ?? 'ACT-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: _name.text.trim(),
      category: _category.text.trim(),
      points: int.tryParse(_points.text.trim()) ?? 0,
      hasQuantity: _hasQuantity,
      isActive: _isActive,
    );
    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.90),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AdminSpacing.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AdminSpacing.md),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AdminSpacing.md + 2,
                AdminSpacing.md,
                AdminSpacing.md + 2,
                AdminSpacing.xs + 2,
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add_task,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AdminSpacing.xs + 6),
                  Text(
                    isEdit ? 'Edit Activity' : 'Add Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AdminSpacing.md + 2,
                  AdminSpacing.xs + 2,
                  AdminSpacing.md + 2,
                  AdminSpacing.md + 2,
                ),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final twoCol = constraints.maxWidth > 700;
                      Widget field(Widget child) => SizedBox(
                        width: twoCol
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth,
                        child: child,
                      );
                      return Wrap(
                        spacing: AdminSpacing.md,
                        runSpacing: AdminSpacing.md,
                        children: [
                          field(
                            _text(
                              _name,
                              'Activity Name *',
                              validator: _required,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          field(_categoryField()),
                          field(
                            _text(
                              _points,
                              'Points *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: Material(
                              type: MaterialType.transparency,
                              child: SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                activeThumbColor: theme.colorScheme.primary,
                                value: _hasQuantity,
                                onChanged: (v) =>
                                    setState(() => _hasQuantity = v),
                                title: const Text('Measured by quantity'),
                                subtitle: const Text(
                                  'Points multiply by the count (e.g. Quran pages).',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: Material(
                              type: MaterialType.transparency,
                              child: SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                activeThumbColor: theme.colorScheme.primary,
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v),
                                title: const Text('Active'),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AdminSpacing.md + 2,
                  AdminSpacing.xs,
                  AdminSpacing.md + 2,
                  AdminSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(isEdit ? 'Save Changes' : 'Add Activity'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (int.tryParse(value.trim()) == null) return 'Enter a number';
    return null;
  }

  Widget _text(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _categoryField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _category.text),
      optionsBuilder: (value) {
        if (value.text.isEmpty) return widget.categories;
        return widget.categories.where(
          (c) => c.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: (value) => _category.text = value,
      fieldViewBuilder: (context, controller, focusNode, _) {
        controller.text = _category.text;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: _required,
          onChanged: (v) => _category.text = v,
          decoration: const InputDecoration(labelText: 'Category *'),
        );
      },
    );
  }
}
