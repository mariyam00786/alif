import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

/// Batch Management (FRP Sec 4.3).
///
/// Add / edit / delete batches with a class/level, assigned teacher, schedule
/// and capacity. No approval queue or export features (out of FRP scope).
class BatchManagementScreen extends StatefulWidget {
  const BatchManagementScreen({
    super.key,
    required this.batches,
    required this.availableTeachers,
    required this.availableClasses,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<BatchClassRecord> batches;
  final List<String> availableTeachers;
  final List<String> availableClasses;
  final ValueChanged<BatchClassRecord> onAdd;
  final ValueChanged<BatchClassRecord> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _classFilter = 'All classes';

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

  List<BatchClassRecord> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return widget.batches.where((batch) {
      final matchesQuery =
          query.isEmpty ||
          batch.name.toLowerCase().contains(query) ||
          batch.teacherName.toLowerCase().contains(query) ||
          batch.className.toLowerCase().contains(query);
      final matchesClass =
          _classFilter == 'All classes' || batch.className == _classFilter;
      return matchesQuery && matchesClass;
    }).toList();
  }

  Future<void> _openForm({BatchClassRecord? existing}) async {
    final result = await showModalBottomSheet<BatchClassRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BatchFormSheet(
        existing: existing,
        teachers: widget.availableTeachers,
        classes: widget.availableClasses,
      ),
    );
    if (result == null) return;
    if (existing == null) {
      widget.onAdd(result);
      if (mounted) showInlineMessage(context, 'Batch added successfully.');
    } else {
      widget.onUpdate(result);
      if (mounted) showInlineMessage(context, 'Batch updated successfully.');
    }
  }

  Future<void> _confirmDelete(BatchClassRecord batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete batch'),
        content: Text('Remove ${batch.name}? This action cannot be undone.'),
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
      widget.onDelete(batch.id);
      if (mounted) showInlineMessage(context, 'Batch removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final enrolled = widget.batches.fold<int>(
      0,
      (sum, item) => sum + item.studentCount,
    );

    return AdminPageFrame(
      title: 'Batch Management',
      subtitle: 'Create batches, assign teachers, and plan class capacity.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Add Batch'),
        ),
      ],
      children: [
        FilterBar(
          searchController: _searchController,
          searchHint: 'Search by batch, class or teacher',
          filterLabel: 'Class',
          filterValue: _classFilter,
          filterOptions: ['All classes', ...widget.availableClasses],
          onFilterChanged: (value) =>
              setState(() => _classFilter = value ?? 'All classes'),
        ),
        StatGrid(
          items: [
            StatItem(
              value: '${widget.batches.length}',
              label: 'Total batches',
              icon: Icons.class_outlined,
            ),
            StatItem(
              value: '$enrolled',
              label: 'Students enrolled',
              icon: Icons.groups_2_outlined,
            ),
            StatItem(
              value: '${filtered.length}',
              label: 'Showing',
              icon: Icons.filter_alt_outlined,
            ),
          ],
        ),
        if (filtered.isEmpty)
          const _EmptyState()
        else
          _BatchList(
            batches: filtered,
            onEdit: (batch) => _openForm(existing: batch),
            onDelete: _confirmDelete,
          ),
      ],
    );
  }
}

class _BatchList extends StatelessWidget {
  const _BatchList({
    required this.batches,
    required this.onEdit,
    required this.onDelete,
  });

  final List<BatchClassRecord> batches;
  final ValueChanged<BatchClassRecord> onEdit;
  final ValueChanged<BatchClassRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final batch in batches)
              _BatchTile(
                batch: batch,
                onEdit: () => onEdit(batch),
                onDelete: () => onDelete(batch),
              ),
          ],
        ),
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({
    required this.batch,
    required this.onEdit,
    required this.onDelete,
  });

  final BatchClassRecord batch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillRatio = batch.capacity == 0
        ? 0.0
        : (batch.studentCount / batch.capacity).clamp(0.0, 1.0);
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
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (batch.className.isNotEmpty)
                    StatusPill(
                      label: batch.className,
                      color: const Color(0xFF1E293B),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '👨‍🏫 ${batch.teacherName.isEmpty ? 'Unassigned' : batch.teacherName}',
                style: theme.textTheme.bodySmall,
              ),
              if (batch.schedule.isNotEmpty)
                Text(
                  '🕒 ${batch.schedule}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: fillRatio,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${batch.studentCount}/${batch.capacity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          );

          final trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
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
              Icons.class_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('No batches found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Try adjusting filters or add a new batch.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit batch form sheet implementing the FRP field set.
class BatchFormSheet extends StatefulWidget {
  const BatchFormSheet({
    super.key,
    this.existing,
    required this.teachers,
    required this.classes,
  });

  final BatchClassRecord? existing;
  final List<String> teachers;
  final List<String> classes;

  @override
  State<BatchFormSheet> createState() => _BatchFormSheetState();
}

class _BatchFormSheetState extends State<BatchFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _schedule;
  late final TextEditingController _capacity;
  String? _className;
  String? _teacher;
  RecordStatus _status = RecordStatus.active;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _schedule = TextEditingController(text: e?.schedule ?? '');
    _capacity = TextEditingController(text: (e?.capacity ?? 30).toString());
    _className = e?.className.isNotEmpty == true ? e?.className : null;
    _teacher = e?.teacherName.isNotEmpty == true ? e?.teacherName : null;
    _status = e?.status ?? RecordStatus.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _schedule.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_className == null) {
      showInlineMessage(context, 'Please select a class.');
      return;
    }
    final e = widget.existing;
    final record = BatchClassRecord(
      id: e?.id ?? 'BAT-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: _name.text.trim(),
      className: _className!,
      teacherId: e?.teacherId ?? '',
      teacherName: _teacher ?? '',
      studentCount: e?.studentCount ?? 0,
      schedule: _schedule.text.trim(),
      capacity: int.tryParse(_capacity.text.trim()) ?? 30,
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
                    isEdit ? Icons.edit : Icons.add_box_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Batch' : 'Add Batch',
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
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _text(
                              _name,
                              'Batch Name *',
                              validator: _required,
                            ),
                          ),
                          field(
                            _dropdown(
                              'Class *',
                              _className,
                              widget.classes,
                              (v) => setState(() => _className = v),
                            ),
                          ),
                          field(
                            _dropdown(
                              'Teacher',
                              _teacher,
                              widget.teachers,
                              (v) => setState(() => _teacher = v),
                            ),
                          ),
                          field(
                            _text(
                              _capacity,
                              'Capacity *',
                              keyboardType: TextInputType.number,
                              validator: _requiredNumber,
                            ),
                          ),
                          field(_statusField()),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _text(
                              _schedule,
                              'Schedule (e.g. Mon, Wed, Fri · 7:00 PM)',
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
                        child: Text(isEdit ? 'Save Changes' : 'Add Batch'),
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

  Widget _statusField() {
    return DropdownButtonFormField<RecordStatus>(
      initialValue: _status,
      decoration: const InputDecoration(labelText: 'Status'),
      items: RecordStatus.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
          .toList(),
      onChanged: (v) => setState(() => _status = v ?? RecordStatus.active),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
