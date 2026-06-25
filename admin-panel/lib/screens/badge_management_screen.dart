import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';
import '../constants/admin_spacing.dart';

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
    try {
      if (existing == null) {
        widget.onAdd(result);
        if (mounted) showInlineMessage(context, 'Badge added successfully.');
      } else {
        widget.onUpdate(result);
        if (mounted) showInlineMessage(context, 'Badge updated successfully.');
      }
    } catch (error) {
      if (mounted) {
        showInlineMessage(context, 'Could not save badge: $error');
      }
    }
  }

  Future<void> _confirmDelete(BadgeDefinition badge) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete badge',
      message: 'Remove ${badge.name}? This action cannot be undone.',
    );
    if (confirmed) {
      try {
        widget.onDelete(badge.id);
        if (mounted) showInlineMessage(context, 'Badge removed.');
      } catch (error) {
        if (mounted) {
          showInlineMessage(context, 'Could not remove badge: $error');
        }
      }
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
            StatItem(
              value:
                  '${widget.badges.fold<int>(0, (sum, b) => sum + b.bonusPoints)}',
              label: 'Bonus points',
              icon: Icons.stars_outlined,
            ),
          ],
        ),
        if (widget.badges.isEmpty)
          const _EmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 560;

              if (isMobile) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.badges.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AdminSpacing.sm),
                  itemBuilder: (context, index) {
                    final badge = widget.badges[index];
                    return Dismissible(
                      key: ValueKey('badge-mobile-${badge.id}'),
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
                        if (direction == DismissDirection.startToEnd) {
                          await _openForm(existing: badge);
                        } else {
                          await _confirmDelete(badge);
                        }
                        return false;
                      },
                      child: _BadgeCard(badge: badge, compact: true),
                    );
                  },
                );
              }

              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.badges.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AdminSpacing.md,
                  mainAxisSpacing: AdminSpacing.md,
                  childAspectRatio: columns == 2 ? 1.38 : 1.3,
                ),
                itemBuilder: (context, index) {
                  final badge = widget.badges[index];
                  return Dismissible(
                    key: ValueKey('badge-grid-${badge.id}'),
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
                      if (direction == DismissDirection.startToEnd) {
                        await _openForm(existing: badge);
                      } else {
                        await _confirmDelete(badge);
                      }
                      return false;
                    },
                    child: _BadgeCard(badge: badge, compact: false),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, this.compact = false});

  final BadgeDefinition badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? AdminSpacing.sm : AdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(AdminSpacing.lg),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 44,
                height: compact ? 34 : 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AdminSpacing.md),
                ),
                child: Text(
                  badge.icon,
                  style: TextStyle(fontSize: compact ? 17 : 22),
                ),
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
          SizedBox(height: compact ? AdminSpacing.xs : AdminSpacing.sm),
          Text(
            badge.name,
            style:
                (compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 2 : AdminSpacing.xs),
          Text(
            badge.criteria,
            style: theme.textTheme.bodySmall,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? AdminSpacing.xs : AdminSpacing.sm),
          Row(
            children: [
              StatusPill(
                label: '+${badge.bonusPoints} pts',
                color: theme.colorScheme.primary,
              ),
              const Spacer(),
              const Icon(
                Icons.swipe_left_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
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
              Icons.military_tech_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text('No badges yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AdminSpacing.xs),
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
  late final TextEditingController _criteria;
  late final TextEditingController _bonus;
  late String _icon;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _criteria = TextEditingController(text: e?.criteria ?? '');
    _bonus = TextEditingController(text: (e?.bonusPoints ?? 0).toString());
    _icon = e?.icon ?? _icons.first;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
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
                    isEdit ? Icons.edit : Icons.add,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AdminSpacing.xs + 6),
                  Text(
                    isEdit ? 'Edit Badge' : 'Add Badge',
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
                            _text(_name, 'Badge Name *', validator: _required),
                          ),
                          field(
                            _text(
                              _bonus,
                              'Bonus Points *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          field(
                            Material(
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
        const SizedBox(height: AdminSpacing.sm),
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
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
                  borderRadius: BorderRadius.circular(AdminSpacing.md),
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
