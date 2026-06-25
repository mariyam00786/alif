import 'package:flutter/material.dart';

import '../model/app_models.dart';
import '../components/admin_ui.dart';
import '../constants/admin_spacing.dart';

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
    try {
      if (existing == null) {
        widget.onAdd(result);
        if (mounted) showInlineMessage(context, 'Teacher added successfully.');
      } else {
        widget.onUpdate(result);
        if (mounted) {
          showInlineMessage(context, 'Teacher updated successfully.');
        }
      }
    } catch (error) {
      if (mounted) {
        showInlineMessage(context, 'Could not save teacher: $error');
      }
    }
  }

  Future<void> _confirmDelete(TeacherRecord teacher) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete teacher',
      message: 'Remove ${teacher.name}? This action cannot be undone.',
    );
    if (confirmed) {
      try {
        widget.onDelete(teacher.id);
        if (mounted) showInlineMessage(context, 'Teacher removed.');
      } catch (error) {
        if (mounted) {
          showInlineMessage(context, 'Could not remove teacher: $error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 560;
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
            compact: isMobile,
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
    this.compact = false,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeacherRecord> teachers;
  final bool compact;
  final ValueChanged<TeacherRecord> onEdit;
  final ValueChanged<TeacherRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < teachers.length; i++)
            Dismissible(
              key: ValueKey('teacher-${teachers[i].id}'),
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
                final teacher = teachers[i];
                if (direction == DismissDirection.startToEnd) {
                  onEdit(teacher);
                } else {
                  onDelete(teacher);
                }
                return false;
              },
              child: _TeacherTile(
                teacher: teachers[i],
                compact: compact,
                showDivider: i < teachers.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  const _TeacherTile({
    required this.teacher,
    required this.showDivider,
    this.compact = false,
  });

  final TeacherRecord teacher;
  final bool showDivider;
  final bool compact;

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

  String get _statusLabel {
    final raw = teacher.status.name;
    return raw.isEmpty ? '-' : '${raw[0].toUpperCase()}${raw.substring(1)}';
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

    final compactMeta = [
      if (teacher.batches.isNotEmpty) 'Batch: ${teacher.batches.first}',
      if (teacher.mobile.isNotEmpty) teacher.mobile,
    ].join('  •  ');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AdminSpacing.sm + 2 : AdminSpacing.md + 2,
        vertical: compact ? AdminSpacing.sm : AdminSpacing.md,
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
          final isCompact = compact || constraints.maxWidth < 620;
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: isCompact ? 16 : 19,
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
              SizedBox(
                width: isCompact ? AdminSpacing.sm + 2 : AdminSpacing.md,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style:
                          (isCompact
                                  ? theme.textTheme.bodyMedium
                                  : theme.textTheme.bodyLarge)
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subjectsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    if (isCompact && compactMeta.isNotEmpty)
                      Text(
                        compactMeta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      )
                    else if (teacher.batches.isNotEmpty)
                      Text(
                        'Batch: ${teacher.batches.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    if (!isCompact && teacher.mobile.isNotEmpty)
                      Text(
                        teacher.mobile,
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
              const _SwipeHintChip(),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AdminSpacing.xs + 2),
                Align(alignment: Alignment.centerRight, child: trailing),
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

class _SwipeHintChip extends StatelessWidget {
  const _SwipeHintChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF64748B)),
          SizedBox(width: 4),
          Icon(Icons.swipe_left_rounded, size: 14, color: Color(0xFF94A3B8)),
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
              Icons.person_off_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text('No teachers found', style: theme.textTheme.titleMedium),
            const SizedBox(height: AdminSpacing.xs),
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
                              'Teacher Name *',
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
        const SizedBox(height: AdminSpacing.sm),
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
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
