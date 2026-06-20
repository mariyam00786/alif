import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

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

  Color _colorFor(String name) => _palette[name] ?? const Color(0xFF2E7D32);

  Future<void> _openForm({RatingRule? existing}) async {
    final result = await showModalBottomSheet<RatingRule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          RatingFormSheet(existing: existing, colors: _palette.keys.toList()),
    );
    if (result == null) return;
    if (existing == null) {
      widget.onAdd(result);
      if (mounted) showInlineMessage(context, 'Rating band added.');
    } else {
      widget.onUpdate(result);
      if (mounted) showInlineMessage(context, 'Rating band updated.');
    }
  }

  Future<void> _confirmDelete(RatingRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete rating band'),
        content: Text('Remove ${rule.label}? This action cannot be undone.'),
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
      widget.onDelete(rule.id);
      if (mounted) showInlineMessage(context, 'Rating band removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.ratingRules]
      ..sort((a, b) => b.maxScore.compareTo(a.maxScore));

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
        if (sorted.isEmpty)
          const _EmptyState()
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final rule in sorted)
                    _RatingTile(
                      rule: rule,
                      color: _colorFor(rule.colorName),
                      onEdit: () => _openForm(existing: rule),
                      onDelete: () => _confirmDelete(rule),
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
  const _RatingTile({
    required this.rule,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final RatingRule rule;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
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
                      const SizedBox(width: 8),
                      const StatusPill(
                        label: 'Default',
                        color: Color(0xFF2E7D32),
                      ),
                    ],
                  ],
                ),
                if (rule.labelMl.isNotEmpty)
                  Text(
                    rule.labelMl,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Score ${rule.minScore} – ${rule.maxScore} · ${rule.colorName}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
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
              Icons.straighten,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('No rating bands yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
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
  late final TextEditingController _labelMl;
  late final TextEditingController _min;
  late final TextEditingController _max;
  String? _color;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _labelMl = TextEditingController(text: e?.labelMl ?? '');
    _min = TextEditingController(text: (e?.minScore ?? 0).toString());
    _max = TextEditingController(text: (e?.maxScore ?? 100).toString());
    _color =
        e?.colorName ?? (widget.colors.isNotEmpty ? widget.colors.first : null);
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _labelMl.dispose();
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
      labelMl: _labelMl.text.trim(),
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
                    isEdit ? Icons.edit : Icons.add,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Band' : 'Add Band',
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
                          field(_text(_label, 'Label *', validator: _required)),
                          field(_text(_labelMl, 'Label (Malayalam)')),
                          field(
                            _text(
                              _min,
                              'Min Score *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          field(
                            _text(
                              _max,
                              'Max Score *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          field(_colorField()),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: theme.colorScheme.primary,
                              value: _isDefault,
                              onChanged: (v) => setState(() => _isDefault = v),
                              title: const Text('Set as default band'),
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
                        child: Text(isEdit ? 'Save Changes' : 'Add Band'),
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

  Widget _colorField() {
    return DropdownButtonFormField<String>(
      initialValue: _color,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Colour'),
      items: widget.colors
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _color = v),
    );
  }
}
