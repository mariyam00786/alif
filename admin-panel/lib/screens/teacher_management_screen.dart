import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

/// Teacher Management (FRP Sec 4.2).
///
/// Add / edit / delete teachers with the required staff fields, subject and
/// batch assignment, plus search and status filters. No approval queue,
/// response-rate metrics, or export features (out of FRP scope).
class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({
    super.key,
    required this.teachers,
    required this.availableSubjects,
    required this.availableBatches,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<TeacherRecord> teachers;
  final List<String> availableSubjects;
  final List<String> availableBatches;
  final ValueChanged<TeacherRecord> onAdd;
  final ValueChanged<TeacherRecord> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All status';

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

  List<TeacherRecord> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return widget.teachers.where((teacher) {
      final matchesQuery =
          query.isEmpty ||
          teacher.name.toLowerCase().contains(query) ||
          teacher.nameMl.toLowerCase().contains(query) ||
          teacher.mobile.toLowerCase().contains(query) ||
          teacher.subjects.join(' ').toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All status' ||
          teacher.status.name == _statusFilter.toLowerCase();
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _openForm({TeacherRecord? existing}) async {
    final result = await showModalBottomSheet<TeacherRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TeacherFormSheet(
        existing: existing,
        subjects: widget.availableSubjects,
        batches: widget.availableBatches,
      ),
    );
    if (result == null) return;
    if (existing == null) {
      widget.onAdd(result);
      if (mounted) showInlineMessage(context, 'Teacher added successfully.');
    } else {
      widget.onUpdate(result);
      if (mounted) showInlineMessage(context, 'Teacher updated successfully.');
    }
  }

  Future<void> _confirmDelete(TeacherRecord teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete teacher'),
        content: Text('Remove ${teacher.name}? This action cannot be undone.'),
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
      widget.onDelete(teacher.id);
      if (mounted) showInlineMessage(context, 'Teacher removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = widget.teachers
        .where((t) => t.status == RecordStatus.active)
        .length;

    return AdminPageFrame(
      title: 'Teacher Management',
      subtitle: 'Add, edit and assign teachers to subjects and batches.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Teacher'),
        ),
      ],
      children: [
        FilterBar(
          searchController: _searchController,
          searchHint: 'Search by name, mobile or subject',
          filterLabel: 'Status',
          filterValue: _statusFilter,
          filterOptions: const ['All status', 'Active', 'Review', 'Archived'],
          onFilterChanged: (value) =>
              setState(() => _statusFilter = value ?? 'All status'),
        ),
        StatGrid(
          items: [
            StatItem(
              value: '${widget.teachers.length}',
              label: 'Total teachers',
              icon: Icons.groups_2_outlined,
            ),
            StatItem(
              value: '$activeCount',
              label: 'Active',
              icon: Icons.verified_user_outlined,
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
          _TeacherList(
            teachers: filtered,
            onEdit: (teacher) => _openForm(existing: teacher),
            onDelete: _confirmDelete,
          ),
      ],
    );
  }
}

class _TeacherList extends StatelessWidget {
  const _TeacherList({
    required this.teachers,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeacherRecord> teachers;
  final ValueChanged<TeacherRecord> onEdit;
  final ValueChanged<TeacherRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final teacher in teachers)
              _TeacherTile(
                teacher: teacher,
                onEdit: () => onEdit(teacher),
                onDelete: () => onDelete(teacher),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  const _TeacherTile({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherRecord teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _statusColor {
    switch (teacher.status) {
      case RecordStatus.active:
        return const Color(0xFF2E7D32);
      case RecordStatus.review:
        return const Color(0xFFFFA000);
      case RecordStatus.archived:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = teacher.name.isNotEmpty
        ? teacher.name.trim()[0].toUpperCase()
        : '?';
    final subjectsLabel = teacher.subjects.isEmpty
        ? 'No subjects'
        : teacher.subjects.join(', ');
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (teacher.nameMl.isNotEmpty)
                      Text(
                        teacher.nameMl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(subjectsLabel, style: theme.textTheme.bodySmall),
                    if (teacher.batches.isNotEmpty)
                      Text(
                        '🎓 ${teacher.batches.join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    if (teacher.mobile.isNotEmpty)
                      Text(
                        '📞 ${teacher.mobile}',
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
              StatusPill(label: teacher.status.name, color: _statusColor),
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
              Icons.person_off_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('No teachers found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Try adjusting filters or add a new teacher.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit teacher form sheet implementing the FRP field set.
class TeacherFormSheet extends StatefulWidget {
  const TeacherFormSheet({
    super.key,
    this.existing,
    required this.subjects,
    required this.batches,
  });

  final TeacherRecord? existing;
  final List<String> subjects;
  final List<String> batches;

  @override
  State<TeacherFormSheet> createState() => _TeacherFormSheetState();
}

class _TeacherFormSheetState extends State<TeacherFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nameMl;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _qualification;
  late final Set<String> _selectedSubjects;
  late final Set<String> _selectedBatches;
  RecordStatus _status = RecordStatus.active;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _nameMl = TextEditingController(text: e?.nameMl ?? '');
    _mobile = TextEditingController(text: e?.mobile ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _qualification = TextEditingController(text: e?.qualification ?? '');
    _selectedSubjects = {...?e?.subjects};
    _selectedBatches = {...?e?.batches};
    _status = e?.status ?? RecordStatus.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameMl.dispose();
    _mobile.dispose();
    _email.dispose();
    _qualification.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjects.isEmpty) {
      showInlineMessage(context, 'Please select at least one subject.');
      return;
    }
    final e = widget.existing;
    final record = TeacherRecord(
      id: e?.id ?? 'TCH-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: _name.text.trim(),
      nameMl: _nameMl.text.trim(),
      mobile: _mobile.text.trim(),
      email: _email.text.trim(),
      qualification: _qualification.text.trim(),
      subjects: _selectedSubjects.toList(),
      batches: _selectedBatches.toList(),
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
                    isEdit ? Icons.edit : Icons.person_add_alt_1,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Teacher' : 'Add Teacher',
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
                              'Teacher Name *',
                              validator: _required,
                            ),
                          ),
                          field(_text(_nameMl, 'Name (Malayalam)')),
                          field(
                            _text(
                              _mobile,
                              'Mobile Number *',
                              keyboardType: TextInputType.phone,
                              validator: _required,
                            ),
                          ),
                          field(
                            _text(
                              _email,
                              'Email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _text(_qualification, 'Qualification'),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _chipSection(
                              label: 'Subjects *',
                              options: widget.subjects,
                              selected: _selectedSubjects,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _chipSection(
                              label: 'Assigned Batches',
                              options: widget.batches,
                              selected: _selectedBatches,
                            ),
                          ),
                          field(_statusField()),
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
                        child: Text(isEdit ? 'Save Changes' : 'Add Teacher'),
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

  Widget _chipSection({
    required String label,
    required List<String> options,
    required Set<String> selected,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) => setState(() {
                if (value) {
                  selected.add(option);
                } else {
                  selected.remove(option);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}
