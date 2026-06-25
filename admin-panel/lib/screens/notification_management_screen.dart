import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';
import '../constants/admin_spacing.dart';

/// Notification Management (FRP Sec 4.7).
///
/// Compose / edit / delete push notifications targeted at all parents, a batch,
/// a class, or a single student, with optional scheduling. No approval workflow
/// or WhatsApp/broadcast export (out of FRP scope).
class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({
    super.key,
    required this.campaigns,
    required this.batches,
    required this.classes,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<NotificationCampaign> campaigns;
  final List<String> batches;
  final List<String> classes;
  final ValueChanged<NotificationCampaign> onAdd;
  final ValueChanged<NotificationCampaign> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  Future<void> _openForm({NotificationCampaign? existing}) async {
    final result = await showModalBottomSheet<NotificationCampaign>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationFormSheet(
        existing: existing,
        batches: widget.batches,
        classes: widget.classes,
      ),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        widget.onAdd(result);
        if (mounted) showInlineMessage(context, 'Notification created.');
      } else {
        widget.onUpdate(result);
        if (mounted) showInlineMessage(context, 'Notification updated.');
      }
    } catch (error) {
      if (mounted) {
        showInlineMessage(context, 'Could not save notification: $error');
      }
    }
  }

  Future<void> _confirmDelete(NotificationCampaign campaign) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete notification',
      message: 'Remove "${campaign.title}"? This action cannot be undone.',
    );
    if (confirmed) {
      try {
        widget.onDelete(campaign.id);
        if (mounted) showInlineMessage(context, 'Notification removed.');
      } catch (error) {
        if (mounted) {
          showInlineMessage(context, 'Could not remove notification: $error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: 'Notification Management',
      subtitle: 'Compose and schedule push notifications for parents.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_alert),
          label: const Text('Compose'),
        ),
      ],
      children: [
        StatGrid(
          items: [
            StatItem(
              value: '${widget.campaigns.length}',
              label: 'Notifications',
              icon: Icons.campaign_outlined,
            ),
            StatItem(
              value:
                  '${widget.campaigns.where((c) => c.status == CampaignStatus.scheduled).length}',
              label: 'Scheduled',
              icon: Icons.schedule,
            ),
            StatItem(
              value:
                  '${widget.campaigns.where((c) => c.status == CampaignStatus.sent).length}',
              label: 'Sent',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
        if (widget.campaigns.isEmpty)
          const _EmptyState()
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < widget.campaigns.length; i++)
                  Dismissible(
                    key: ValueKey('notification-${widget.campaigns[i].id}'),
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
                      final campaign = widget.campaigns[i];
                      if (direction == DismissDirection.startToEnd) {
                        await _openForm(existing: campaign);
                      } else {
                        await _confirmDelete(campaign);
                      }
                      return false;
                    },
                    child: _NotificationTile(
                      campaign: widget.campaigns[i],
                      showDivider: i < widget.campaigns.length - 1,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.campaign, required this.showDivider});

  final NotificationCampaign campaign;
  final bool showDivider;

  (Color, String) get _statusInfo {
    switch (campaign.status) {
      case CampaignStatus.sent:
        return (const Color(0xFF2E7D32), 'sent');
      case CampaignStatus.scheduled:
        return (const Color(0xFFFFA000), 'scheduled');
      case CampaignStatus.draft:
        return (const Color(0xFF9E9E9E), 'draft');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusColor, statusLabel) = _statusInfo;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md + 2,
        vertical: AdminSpacing.md,
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
          final isCompact = constraints.maxWidth < 620;
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (campaign.message.isNotEmpty)
                      Text(
                        campaign.message,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      '🎯 ${campaign.audience}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    if (campaign.scheduledFor.isNotEmpty)
                      Text(
                        '🕒 ${campaign.scheduledFor}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );

          final trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(label: statusLabel, color: statusColor),
              const SizedBox(width: AdminSpacing.xs + 6),
              const Icon(
                Icons.swipe_left_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AdminSpacing.xs + 6),
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              trailing,
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
              Icons.campaign_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text('No notifications yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              'Compose a notification to reach parents.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

enum _TargetType { all, batch, className, student }

/// Compose / edit notification form sheet implementing the FRP field set.
class NotificationFormSheet extends StatefulWidget {
  const NotificationFormSheet({
    super.key,
    this.existing,
    required this.batches,
    required this.classes,
  });

  final NotificationCampaign? existing;
  final List<String> batches;
  final List<String> classes;

  @override
  State<NotificationFormSheet> createState() => _NotificationFormSheetState();
}

class _NotificationFormSheetState extends State<NotificationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _message;
  late final TextEditingController _target;
  _TargetType _targetType = _TargetType.all;
  String? _targetValue;
  CampaignStatus _status = CampaignStatus.draft;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _message = TextEditingController(text: e?.message ?? '');
    _target = TextEditingController(text: e?.audience ?? '');
    _status = e?.status ?? CampaignStatus.draft;
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _target.dispose();
    super.dispose();
  }

  String _composeAudience() {
    switch (_targetType) {
      case _TargetType.all:
        return 'Parents · All batches';
      case _TargetType.batch:
        return 'Batch · ${_targetValue ?? ''}';
      case _TargetType.className:
        return 'Class · ${_targetValue ?? ''}';
      case _TargetType.student:
        return 'Student · ${_target.text.trim()}';
    }
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_targetType != _TargetType.all &&
        _targetType != _TargetType.student &&
        _targetValue == null) {
      showInlineMessage(context, 'Please choose a target.');
      return;
    }
    final scheduled = _scheduledAt != null
        ? '${_scheduledAt!.day.toString().padLeft(2, '0')}/'
              '${_scheduledAt!.month.toString().padLeft(2, '0')} · '
              '${_scheduledAt!.hour.toString().padLeft(2, '0')}:'
              '${_scheduledAt!.minute.toString().padLeft(2, '0')}'
        : (widget.existing?.scheduledFor ?? '');
    final e = widget.existing;
    final record = NotificationCampaign(
      id: e?.id ?? 'NTF-${DateTime.now().millisecondsSinceEpoch % 100000}',
      title: _title.text.trim(),
      message: _message.text.trim(),
      audience: _composeAudience(),
      scheduledFor: scheduled,
      status: _status,
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
                    isEdit ? Icons.edit : Icons.add_alert,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AdminSpacing.xs + 6),
                  Text(
                    isEdit ? 'Edit Notification' : 'Compose Notification',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _title,
                        validator: _required,
                        decoration: const InputDecoration(labelText: 'Title *'),
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      TextFormField(
                        controller: _message,
                        validator: _required,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      DropdownButtonFormField<_TargetType>(
                        initialValue: _targetType,
                        decoration: const InputDecoration(labelText: 'Target'),
                        items: const [
                          DropdownMenuItem(
                            value: _TargetType.all,
                            child: Text('All parents'),
                          ),
                          DropdownMenuItem(
                            value: _TargetType.batch,
                            child: Text('Specific batch'),
                          ),
                          DropdownMenuItem(
                            value: _TargetType.className,
                            child: Text('Specific class'),
                          ),
                          DropdownMenuItem(
                            value: _TargetType.student,
                            child: Text('Specific student'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _targetType = v ?? _TargetType.all;
                          _targetValue = null;
                        }),
                      ),
                      if (_targetType == _TargetType.batch ||
                          _targetType == _TargetType.className) ...[
                        const SizedBox(height: AdminSpacing.lg),
                        DropdownButtonFormField<String>(
                          initialValue: _targetValue,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _targetType == _TargetType.batch
                                ? 'Choose batch'
                                : 'Choose class',
                          ),
                          items:
                              (_targetType == _TargetType.batch
                                      ? widget.batches
                                      : widget.classes)
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(o),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _targetValue = v),
                        ),
                      ],
                      if (_targetType == _TargetType.student) ...[
                        const SizedBox(height: AdminSpacing.lg),
                        TextFormField(
                          controller: _target,
                          decoration: const InputDecoration(
                            labelText: 'Student name or ID',
                          ),
                        ),
                      ],
                      const SizedBox(height: AdminSpacing.lg),
                      DropdownButtonFormField<CampaignStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: CampaignStatus.draft,
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: CampaignStatus.scheduled,
                            child: Text('Scheduled'),
                          ),
                          DropdownMenuItem(
                            value: CampaignStatus.sent,
                            child: Text('Sent'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? CampaignStatus.draft),
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Schedule (optional)',
                        ),
                        child: InkWell(
                          onTap: _pickSchedule,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _scheduledAt == null
                                      ? (widget
                                                    .existing
                                                    ?.scheduledFor
                                                    .isNotEmpty ==
                                                true)
                                            ? widget.existing!.scheduledFor
                                            : 'Send immediately'
                                      : '${_scheduledAt!.day}/${_scheduledAt!.month} · '
                                            '${_scheduledAt!.hour.toString().padLeft(2, '0')}:'
                                            '${_scheduledAt!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                              const Icon(Icons.schedule, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AdminSpacing.xl,
                  AdminSpacing.xs,
                  AdminSpacing.xl,
                  AdminSpacing.lg,
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
                        child: Text(isEdit ? 'Save Changes' : 'Create'),
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
}
