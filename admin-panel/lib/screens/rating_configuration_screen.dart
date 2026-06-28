import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';
import '../constants/admin_spacing.dart';

/// Rating / Scoring Configuration (FRP Sec 4.5).
///
/// Add / edit / delete score bands that classify a student's total score into
/// labels (e.g. Excellent, Good) with a colour. One band can be the default.
/// No export or follow-up-action features (out of FRP scope).
class RatingConfigurationScreen extends StatefulWidget {
  const RatingConfigurationScreen({
    super.key,
    required this.ratingRules,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<RatingRule> ratingRules;
  final ValueChanged<RatingRule> onAdd;
  final ValueChanged<RatingRule> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<RatingConfigurationScreen> createState() =>
      _RatingConfigurationScreenState();
}

class _RatingConfigurationScreenState extends State<RatingConfigurationScreen> {
  static const Map<String, Color> _palette = {
    'Green': Color(0xFF2E7D32),
    'Light Green': Color(0xFF66BB6A),
    'Gold': Color(0xFFFFA000),
    'Orange': Color(0xFFFB8C00),
    'Red': Color(0xFFE53935),
    'Blue': Color(0xFF1E88E5),
  };

  // Track which activity groups are expanded/collapsed
  final Set<String> _expandedGroups = {};

  Color _colorFor(String name) {
    if (name.startsWith('#')) {
      final hex = name.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    // Try to find a matching name in the palette (case-insensitive)
    final matchedKey = _palette.keys.firstWhere(
      (k) => k.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );
    if (matchedKey.isNotEmpty) {
      return _palette[matchedKey]!;
    }
    return const Color(0xFF2E7D32);
  }

  Future<void> _openForm({RatingRule? existing}) async {
    final result = await showModalBottomSheet<RatingRule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          RatingFormSheet(existing: existing, colors: _palette.keys.toList()),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        widget.onAdd(result);
        if (mounted) showInlineMessage(context, 'Rating band added.');
      } else {
        widget.onUpdate(result);
        if (mounted) showInlineMessage(context, 'Rating band updated.');
      }
    } catch (error) {
      if (mounted) {
        showInlineMessage(context, 'Could not save rating band: $error');
      }
    }
  }

  Future<void> _confirmDelete(RatingRule rule) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete rating band',
      message: 'Remove ${rule.label}? This action cannot be undone.',
    );
    if (confirmed) {
      try {
        widget.onDelete(rule.id);
        if (mounted) showInlineMessage(context, 'Rating band removed.');
      } catch (error) {
        if (mounted) {
          showInlineMessage(context, 'Could not remove rating band: $error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group bands by activity so identical scales no longer look like dozens
    // of duplicate rows. Activities are listed alphabetically; bands within
    // each activity are ordered by descending score.
    final groups = <String, List<RatingRule>>{};
    for (final rule in widget.ratingRules) {
      final key = rule.activityName.isNotEmpty ? rule.activityName : 'General';
      (groups[key] ??= []).add(rule);
    }
    for (final list in groups.values) {
      list.sort((a, b) => b.maxScore.compareTo(a.maxScore));
    }
    final groupNames = groups.keys.toList()..sort();

    return AdminPageFrame(
      title: 'Rating & Scoring',
      subtitle: 'Define score bands that classify each student\'s progress.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Band'),
        ),
      ],
      children: [
        StatGrid(
          items: [
            StatItem(
              value: '${groupNames.length}',
              label: 'Score scales',
              icon: Icons.list_alt,
            ),
            StatItem(
              value: '${widget.ratingRules.length}',
              label: 'Score bands',
              icon: Icons.straighten,
            ),
            StatItem(
              value: '${widget.ratingRules.where((r) => r.isDefault).length}',
              label: 'Default',
              icon: Icons.star_outline,
            ),
          ],
        ),
        if (groupNames.isEmpty)
          const _EmptyState()
        else
          for (final activity in groupNames)
            Card(
              margin: const EdgeInsets.only(bottom: AdminSpacing.md),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _expandedGroups.contains(activity) || _expandedGroups.isEmpty,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      if (expanded) {
                        _expandedGroups.add(activity);
                      } else {
                        _expandedGroups.remove(activity);
                      }
                    });
                  },
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    activity,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  subtitle: Text(
                    '${groups[activity]!.length} score bands configured',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AdminSpacing.md,
                        0,
                        AdminSpacing.md,
                        AdminSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: AdminSpacing.sm),
                          for (var i = 0; i < groups[activity]!.length; i++)
                            Dismissible(
                              key: ValueKey(
                                'rating-${groups[activity]![i].id}-$activity',
                              ),
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
                                final rule = groups[activity]![i];
                                if (direction == DismissDirection.startToEnd) {
                                  await _openForm(existing: rule);
                                } else {
                                  await _confirmDelete(rule);
                                }
                                return false;
                              },
                              child: _RatingTile(
                                rule: groups[activity]![i],
                                color: _colorFor(groups[activity]![i].colorName),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.rule, required this.color});

  final RatingRule rule;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AdminSpacing.xs + 2),
      padding: const EdgeInsets.all(AdminSpacing.md + 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(AdminSpacing.lg),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AdminSpacing.sm),
            ),
          ),
          const SizedBox(width: AdminSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        rule.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (rule.isDefault) ...[
                      const SizedBox(width: AdminSpacing.sm),
                      const StatusPill(
                        label: 'Default',
                        color: Color(0xFF2E7D32),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rule.minScore == rule.maxScore
                      ? '${rule.maxScore} marks · ${rule.colorName}'
                      : 'Score ${rule.minScore} – ${rule.maxScore} · ${rule.colorName}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminSpacing.xs + 6),
          const Icon(
            Icons.swipe_left_rounded,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
        ],
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
              Icons.straighten,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text('No rating bands yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              'Add a score band to classify student progress.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit rating band form sheet.
class RatingFormSheet extends StatefulWidget {
  const RatingFormSheet({super.key, this.existing, required this.colors});

  final RatingRule? existing;
  final List<String> colors;

  @override
  State<RatingFormSheet> createState() => _RatingFormSheetState();
}

class _RatingFormSheetState extends State<RatingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _min;
  late final TextEditingController _max;
  String? _color;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _min = TextEditingController(text: (e?.minScore ?? 0).toString());
    _max = TextEditingController(text: (e?.maxScore ?? 100).toString());
    _color =
        e?.colorName ?? (widget.colors.isNotEmpty ? widget.colors.first : null);
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final min = int.tryParse(_min.text.trim()) ?? 0;
    final max = int.tryParse(_max.text.trim()) ?? 0;
    if (min > max) {
      showInlineMessage(context, 'Min score cannot be greater than max score.');
      return;
    }
    final e = widget.existing;
    final record = RatingRule(
      id: e?.id ?? 'RATE-${DateTime.now().millisecondsSinceEpoch % 100000}',
      label: _label.text.trim(),
      minScore: min,
      maxScore: max,
      colorName: _color ?? 'Green',
      isDefault: _isDefault,
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
                AdminSpacing.xl,
                AdminSpacing.lg,
                AdminSpacing.xl,
                AdminSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AdminSpacing.xs + 6),
                  Text(
                    isEdit ? 'Edit Band' : 'Add Band',
                    style: theme.textTheme.titleLarge,
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
                  AdminSpacing.xl,
                  AdminSpacing.sm,
                  AdminSpacing.xl,
                  AdminSpacing.xl,
                ),
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
                        spacing: AdminSpacing.md,
                        runSpacing: AdminSpacing.md,
                        children: [
                          field(_text(_label, 'Label *', validator: _required, textCapitalization: TextCapitalization.words)),
                          field(
                            _text(
                              _minScore,
                              'Min Score *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          field(
                            _text(
                              _maxScore,
                              'Max Score *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          field(_colorField()),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _text(
                              _description,
                              'Description',
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
                        child: Text(isEdit ? 'Save Changes' : 'Add Rating Band'),
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

  Widget _colorField() {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: _color,
      isExpanded: true,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.normal,
      ),
      decoration: const InputDecoration(labelText: 'Colour'),
      items: widget.colors
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _color = v),
    );
  }
}
