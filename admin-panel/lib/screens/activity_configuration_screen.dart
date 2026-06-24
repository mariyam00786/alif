import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

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
      return query.isEmpty ||
          a.name.toLowerCase().contains(query) ||
          a.category.toLowerCase().contains(query);
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
          filterLabel: 'Categories',
          filterValue: '${_categories.length} categories',
          filterOptions: ['${_categories.length} categories'],
          onFilterChanged: (_) {},
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
        if (filtered.isEmpty)
          const _EmptyState()
        else
          for (final key in categoryKeys)
            _CategoryGroup(
              category: key,
              activities: grouped[key]!,
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
    required this.onEdit,
    required this.onDelete,
  });

  final String category;
  final List<ActivityRule> activities;
  final ValueChanged<ActivityRule> onEdit;
  final ValueChanged<ActivityRule> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: '${activities.length}',
                    color: const Color(0xFF1E293B),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final a in activities)
                _ActivityTile(
                  activity: a,
                  onEdit: () => onEdit(a),
                  onDelete: () => onDelete(a),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.onEdit,
    required this.onDelete,
  });

  final ActivityRule activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 460;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final meta = Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                label: '${activity.points} pts',
                color: theme.colorScheme.primary,
              ),
              if (activity.hasQuantity)
                const StatusPill(label: 'per qty', color: Color(0xFF1E293B)),
              StatusPill(
                label: activity.isActive ? 'active' : 'inactive',
                color: activity.isActive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF9E9E9E),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                color: theme.colorScheme.primary,
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                onPressed: onDelete,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 6), meta],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              meta,
            ],
          );
        },
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
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.tune,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('No activities found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
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
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add_task,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final twoCol = constraints.maxWidth > 520;
                      Widget field(Widget child) => SizedBox(
                        width: twoCol
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth,
                        child: child,
                      );
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          field(
                            _text(
                              _name,
                              'Activity Name *',
                              validator: _required,
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
                                onChanged: (v) =>
                                    setState(() => _isActive = v),
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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
