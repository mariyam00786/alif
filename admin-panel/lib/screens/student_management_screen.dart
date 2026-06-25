import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';
import '../constants/admin_spacing.dart';

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
  final Future<void> Function(StudentRecord) onAdd;
  final Future<void> Function(StudentRecord) onUpdate;
  final Future<void> Function(String) onDelete;

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
    try {
      if (existing == null) {
        await widget.onAdd(result);
        if (mounted) {
          showInlineMessage(context, 'Student added successfully.');
        }
      } else {
        await widget.onUpdate(result);
        if (mounted) {
          showInlineMessage(context, 'Student updated successfully.');
        }
      }
    } catch (error) {
      if (mounted) {
        showInlineMessage(context, 'Could not save student: $error');
      }
    }
  }

  Future<void> _confirmDelete(StudentRecord student) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete student',
      message: 'Remove ${student.name}? This action cannot be undone.',
    );
    if (confirmed) {
      try {
        await widget.onDelete(student.id);
        if (mounted) showInlineMessage(context, 'Student removed.');
      } catch (error) {
        if (mounted) {
          showInlineMessage(context, 'Could not remove student: $error');
        }
      }
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < students.length; i++)
            Dismissible(
              key: ValueKey('student-${students[i].id}'),
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
                final student = students[i];
                if (direction == DismissDirection.startToEnd) {
                  onEdit(student);
                } else {
                  onDelete(student);
                }
                return false;
              },
              child: _StudentTile(
                student: students[i],
                showDivider: i < students.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.showDivider});

  final StudentRecord student;
  final bool showDivider;

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

  String get _statusLabel {
    final raw = student.status.name;
    return raw.isEmpty ? '-' : '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = student.name.isNotEmpty
        ? student.name.trim()[0].toUpperCase()
        : '?';
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${student.batch}'
                      '${student.className.isNotEmpty ? ' · ${student.className}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    if (student.mobile.isNotEmpty)
                      Text(
                        student.mobile,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
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
              StatusPill(label: _statusLabel, color: _statusColor),
              const SizedBox(width: AdminSpacing.xs + 6),
              Icon(
                Icons.swipe_left_rounded,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AdminSpacing.xs + 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: trailing,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: trailing,
              ),
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
              Icons.group_off_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text('No students found', style: theme.textTheme.titleMedium),
            const SizedBox(height: AdminSpacing.xs),
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
      showInlineMessage(context, 'Please complete batch and date of birth.');
      return;
    }
    final e = widget.existing;
    final record = StudentRecord(
      id: e?.id ?? 'STU-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: _name.text.trim(),
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
                    isEdit ? Icons.edit : Icons.person_add_alt_1,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AdminSpacing.xs + 6),
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
                        spacing: AdminSpacing.lg,
                        runSpacing: AdminSpacing.lg,
                        children: [
                          field(
                            _text(
                              _name,
                              'Student Name *',
                              validator: _required,
                            ),
                          ),
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
