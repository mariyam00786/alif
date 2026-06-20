import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

/// Badge Management (FRP Sec 4.6).
///
/// Add / edit / delete recognition badges with an icon, criteria and bonus
/// points. No publish-approval or recipient-export features (out of FRP scope).
class BadgeManagementScreen extends StatefulWidget {
  const BadgeManagementScreen({
    super.key,
    required this.badges,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<BadgeDefinition> badges;
  final ValueChanged<BadgeDefinition> onAdd;
  final ValueChanged<BadgeDefinition> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<BadgeManagementScreen> createState() => _BadgeManagementScreenState();
}

class _BadgeManagementScreenState extends State<BadgeManagementScreen> {
  Future<void> _openForm({BadgeDefinition? existing}) async {
    final result = await showModalBottomSheet<BadgeDefinition>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BadgeFormSheet(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      widget.onAdd(result);
      if (mounted) showInlineMessage(context, 'Badge added successfully.');
    } else {
      widget.onUpdate(result);
      if (mounted) showInlineMessage(context, 'Badge updated successfully.');
    }
  }

  Future<void> _confirmDelete(BadgeDefinition badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete badge'),
        content: Text('Remove ${badge.name}? This action cannot be undone.'),
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
      widget.onDelete(badge.id);
      if (mounted) showInlineMessage(context, 'Badge removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: 'Badge Management',
      subtitle: 'Create achievement badges and the bonus points they award.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Badge'),
        ),
      ],
      children: [
        StatGrid(
          items: [
            StatItem(
              value: '${widget.badges.length}',
              label: 'Badges',
              icon: Icons.military_tech_outlined,
            ),
            StatItem(
              value: '${widget.badges.where((b) => b.isActive).length}',
              label: 'Active',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
        if (widget.badges.isEmpty)
          const _EmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.6 : 1.5,
                children: [
                  for (final badge in widget.badges)
                    _BadgeCard(
                      badge: badge,
                      onEdit: () => _openForm(existing: badge),
                      onDelete: () => _confirmDelete(badge),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.onEdit,
    required this.onDelete,
  });

  final BadgeDefinition badge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge.icon, style: const TextStyle(fontSize: 22)),
              ),
              const Spacer(),
              StatusPill(
                label: badge.isActive ? 'active' : 'inactive',
                color: badge.isActive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF9E9E9E),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            badge.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (badge.nameMl.isNotEmpty)
            Text(
              badge.nameMl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              badge.criteria,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StatusPill(
                label: '+${badge.bonusPoints} pts',
                color: theme.colorScheme.primary,
              ),
              const Spacer(),
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
              Icons.military_tech_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('No badges yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Create a badge to recognise student achievements.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit badge form sheet implementing the FRP field set.
class BadgeFormSheet extends StatefulWidget {
  const BadgeFormSheet({super.key, this.existing});

  final BadgeDefinition? existing;

  @override
  State<BadgeFormSheet> createState() => _BadgeFormSheetState();
}

class _BadgeFormSheetState extends State<BadgeFormSheet> {
  static const List<String> _icons = [
    '🏅',
    '⭐',
    '🏆',
    '📖',
    '🌙',
    '🤲',
    '💎',
    '🔥',
    '🎯',
    '👑',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nameMl;
  late final TextEditingController _criteria;
  late final TextEditingController _bonus;
  late String _icon;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _nameMl = TextEditingController(text: e?.nameMl ?? '');
    _criteria = TextEditingController(text: e?.criteria ?? '');
    _bonus = TextEditingController(text: (e?.bonusPoints ?? 0).toString());
    _icon = e?.icon ?? _icons.first;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameMl.dispose();
    _criteria.dispose();
    _bonus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final e = widget.existing;
    final record = BadgeDefinition(
      id: e?.id ?? 'BDG-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: _name.text.trim(),
      nameMl: _nameMl.text.trim(),
      criteria: _criteria.text.trim(),
      icon: _icon,
      bonusPoints: int.tryParse(_bonus.text.trim()) ?? 0,
      recipientCount: e?.recipientCount ?? 0,
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
                    isEdit ? Icons.edit : Icons.add,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Badge' : 'Add Badge',
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
                            _text(_name, 'Badge Name *', validator: _required),
                          ),
                          field(_text(_nameMl, 'Name (Malayalam)')),
                          field(
                            _text(
                              _bonus,
                              'Bonus Points *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          field(
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: theme.colorScheme.primary,
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              title: const Text('Active'),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _text(
                              _criteria,
                              'Criteria *',
                              validator: _required,
                              maxLines: 2,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _iconPicker(),
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
                        child: Text(isEdit ? 'Save Changes' : 'Add Badge'),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _iconPicker() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _icons.map((emoji) {
            final selected = emoji == _icon;
            return GestureDetector(
              onTap: () => setState(() => _icon = emoji),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : const Color(0xFFF4F8F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : const Color(0xFFE2E8F0),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
