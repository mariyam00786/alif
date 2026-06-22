import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';

/// Student Management (FRP Sec 4.1.2).
///
/// Provides the full add / edit / delete workflow with the required student
/// fields, plus search and batch / class / status filters. No export or
/// approval-queue features (out of FRP scope).
class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({
    super.key,
    required this.students,
    required this.availableBatches,
    required this.availableClasses,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<StudentRecord> students;
  final List<String> availableBatches;
  final List<String> availableClasses;
  final ValueChanged<StudentRecord> onAdd;
  final ValueChanged<StudentRecord> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _batchFilter = 'All batches';
  String _classFilter = 'All classes';
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

  List<StudentRecord> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return widget.students.where((student) {
      final matchesQuery =
          query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.nameMl.toLowerCase().contains(query) ||
          student.mobile.toLowerCase().contains(query) ||
          student.batch.toLowerCase().contains(query);
      final matchesBatch =
          _batchFilter == 'All batches' || student.batch == _batchFilter;
      final matchesClass =
          _classFilter == 'All classes' || student.className == _classFilter;
      final matchesStatus =
          _statusFilter == 'All status' ||
          student.status.name == _statusFilter.toLowerCase();
      return matchesQuery && matchesBatch && matchesClass && matchesStatus;
    }).toList();
  }

  Future<void> _openForm({StudentRecord? existing}) async {
    final result = await showModalBottomSheet<StudentRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudentFormSheet(
        existing: existing,
        batches: widget.availableBatches,
        classes: widget.availableClasses,
      ),
    );
    if (result == null) return;
    if (existing == null) {
      widget.onAdd(result);
      if (mounted) showInlineMessage(context, 'Student added successfully.');
    } else {
      widget.onUpdate(result);
      if (mounted) showInlineMessage(context, 'Student updated successfully.');
    }
  }

  Future<void> _confirmDelete(StudentRecord student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete student'),
        content: Text('Remove ${student.name}? This action cannot be undone.'),
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
      widget.onDelete(student.id);
      if (mounted) showInlineMessage(context, 'Student removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = widget.students
        .where((s) => s.status == RecordStatus.active)
        .length;

    return AdminPageFrame(
      title: 'Student Management',
      subtitle: 'Add, edit, search and organise student admissions.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Student'),
        ),
      ],
      children: [
        FilterBar(
          searchController: _searchController,
          searchHint: 'Search by name, mobile or batch',
          filterLabel: 'Batch',
          filterValue: _batchFilter,
          filterOptions: ['All batches', ...widget.availableBatches],
          onFilterChanged: (value) =>
              setState(() => _batchFilter = value ?? 'All batches'),
          extraActions: [
            CompactFilterDropdown(
              value: _classFilter,
              options: ['All classes', ...widget.availableClasses],
              onChanged: (value) =>
                  setState(() => _classFilter = value ?? 'All classes'),
            ),
            CompactFilterDropdown(
              value: _statusFilter,
              options: const ['All status', 'Active', 'Review', 'Archived'],
              onChanged: (value) =>
                  setState(() => _statusFilter = value ?? 'All status'),
            ),
          ],
        ),
        StatGrid(
          items: [
            StatItem(
              value: '${widget.students.length}',
              label: 'Total students',
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
          _StudentList(
            students: filtered,
            onEdit: (student) => _openForm(existing: student),
            onDelete: _confirmDelete,
          ),
      ],
    );
  }
}

class _StudentList extends StatelessWidget {
  const _StudentList({
    required this.students,
    required this.onEdit,
    required this.onDelete,
  });

  final List<StudentRecord> students;
  final ValueChanged<StudentRecord> onEdit;
  final ValueChanged<StudentRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final student in students)
              _StudentTile(
                student: student,
                onEdit: () => onEdit(student),
                onDelete: () => onDelete(student),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  final StudentRecord student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _statusColor {
    switch (student.status) {
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
    final initials = student.name.isNotEmpty
        ? student.name.trim()[0].toUpperCase()
        : '?';
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
                      student.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (student.nameMl.isNotEmpty)
                      Text(
                        student.nameMl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.batch}'
                      '${student.className.isNotEmpty ? ' · ${student.className}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (student.mobile.isNotEmpty)
                      Text(
                        '📞 ${student.mobile}',
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
              StatusPill(label: student.status.name, color: _statusColor),
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
              Icons.group_off_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('No students found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Try adjusting filters or add a new student.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit student form sheet implementing the FRP field set.
class StudentFormSheet extends StatefulWidget {
  const StudentFormSheet({
    super.key,
    this.existing,
    required this.batches,
    required this.classes,
  });

  final StudentRecord? existing;
  final List<String> batches;
  final List<String> classes;

  @override
  State<StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends State<StudentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nameMl;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _father;
  late final TextEditingController _mother;
  late final TextEditingController _address;
  DateTime? _dob;
  Gender _gender = Gender.male;
  String? _batch;
  String? _className;
  RecordStatus _status = RecordStatus.active;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _nameMl = TextEditingController(text: e?.nameMl ?? '');
    _mobile = TextEditingController(text: e?.mobile ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _father = TextEditingController(text: e?.fatherName ?? '');
    _mother = TextEditingController(text: e?.motherName ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _dob = e?.dateOfBirth;
    _gender = e?.gender ?? Gender.male;
    _batch = e?.batch.isNotEmpty == true ? e?.batch : null;
    _className = e?.className.isNotEmpty == true ? e?.className : null;
    _status = e?.status ?? RecordStatus.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameMl.dispose();
    _mobile.dispose();
    _email.dispose();
    _father.dispose();
    _mother.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2014, 1, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_batch == null || _dob == null) {
      showInlineMessage(
        context,
        'Please complete batch and date of birth.',
      );
      return;
    }
    final e = widget.existing;
    final record = StudentRecord(
      id: e?.id ?? 'STU-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: _name.text.trim(),
      nameMl: _nameMl.text.trim(),
      mobile: _mobile.text.trim(),
      email: _email.text.trim(),
      fatherName: _father.text.trim(),
      motherName: _mother.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      batch: _batch!,
      className: _className ?? '',
      address: _address.text.trim(),
      guardianName: _father.text.trim(),
      score: e?.score ?? 0,
      streak: e?.streak ?? 0,
      status: _status,
      enrollmentDate: e?.enrollmentDate ?? DateTime.now(),
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
                    isEdit ? 'Edit Student' : 'Add Student',
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
                              'Student Name *',
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
                              'Login Email (for student portal)',
                              keyboardType: TextInputType.emailAddress,
                              validator: _optionalEmail,
                            ),
                          ),
                          field(
                            _text(
                              _father,
                              "Father's Name *",
                              validator: _required,
                            ),
                          ),
                          field(
                            _text(
                              _mother,
                              "Mother's Name *",
                              validator: _required,
                            ),
                          ),
                          field(_dobField()),
                          field(_genderField()),
                          field(
                            _dropdown(
                              'Batch *',
                              _batch,
                              widget.batches,
                              (v) => setState(() => _batch = v),
                            ),
                          ),
                          field(
                            _dropdown(
                              'Class',
                              _className,
                              widget.classes,
                              (v) => setState(() => _className = v),
                            ),
                          ),
                          field(_statusField()),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _text(_address, 'Address', maxLines: 2),
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
                        child: Text(isEdit ? 'Save Changes' : 'Add Student'),
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

  /// Optional email: blank is allowed, but a non-empty value must look valid.
  String? _optionalEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text);
    return isValid ? null : 'Enter a valid email';
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

  Widget _dobField() {
    final text = _dob == null
        ? 'Select date'
        : '${_dob!.day.toString().padLeft(2, '0')}/'
              '${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Date of Birth *'),
      child: InkWell(
        onTap: _pickDob,
        child: Row(
          children: [
            Expanded(child: Text(text)),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _genderField() {
    return DropdownButtonFormField<Gender>(
      initialValue: _gender,
      decoration: const InputDecoration(labelText: 'Gender *'),
      items: const [
        DropdownMenuItem(value: Gender.male, child: Text('Male')),
        DropdownMenuItem(value: Gender.female, child: Text('Female')),
      ],
      onChanged: (v) => setState(() => _gender = v ?? Gender.male),
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
