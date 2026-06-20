import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

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
    if (existing == null) {
      widget.onAdd(result);
      if (mounted) showInlineMessage(context, 'Notification created.');
    } else {
      widget.onUpdate(result);
      if (mounted) showInlineMessage(context, 'Notification updated.');
    }
  }

  Future<void> _confirmDelete(NotificationCampaign campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification'),
        content: Text(
          'Remove "${campaign.title}"? This action cannot be undone.',
        ),
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
      widget.onDelete(campaign.id);
      if (mounted) showInlineMessage(context, 'Notification removed.');
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final campaign in widget.campaigns)
                    _NotificationTile(
                      campaign: campaign,
                      onEdit: () => _openForm(existing: campaign),
                      onDelete: () => _confirmDelete(campaign),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.campaign,
    required this.onEdit,
    required this.onDelete,
  });

  final NotificationCampaign campaign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
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
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
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
              children: [
                info,
                const SizedBox(height: 10),
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
              Icons.campaign_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('No notifications yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
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
                    isEdit ? Icons.edit : Icons.add_alert,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Notification' : 'Compose Notification',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _title,
                        validator: _required,
                        decoration: const InputDecoration(labelText: 'Title *'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _message,
                        validator: _required,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _target,
                          decoration: const InputDecoration(
                            labelText: 'Student name or ID',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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
