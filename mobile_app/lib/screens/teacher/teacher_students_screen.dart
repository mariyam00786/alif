import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import 'teacher_data.dart';

/// Teacher student monitoring (FRD §4.3.2).
///
/// Lists students grouped/filtered by batch. Tapping a student opens the
/// individual progress + remarks detail.
class TeacherStudentsScreen extends StatefulWidget {
  final bool isMalayalam;
  final List<TeacherBatch> batches;
  final List<TeacherStudent> students;
  final ValueChanged<TeacherStudent> onOpenStudent;

  /// Optional batch to pre-select when opened from the dashboard.
  final String? initialBatchId;

  const TeacherStudentsScreen({
    super.key,
    required this.isMalayalam,
    required this.batches,
    required this.students,
    required this.onOpenStudent,
    this.initialBatchId,
  });

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  late String? _batchId = widget.initialBatchId;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void didUpdateWidget(covariant TeacherStudentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBatchId != widget.initialBatchId) {
      _batchId = widget.initialBatchId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeacherStudent> get _filtered {
    return widget.students.where((s) {
      final matchesBatch = _batchId == null || s.batchId == _batchId;
      final q = _query.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.nameMl.contains(q);
      return matchesBatch && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;
    final list = _filtered;

    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'വിദ്യാർഥികൾ' : 'Students',
            subtitle: isMalayalam
                ? 'ബാച്ച് അനുസരിച്ച് നിരീക്ഷിക്കുക'
                : 'Monitor students by batch',
            icon: Icons.groups_rounded,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: isMalayalam
                        ? 'പേര് തിരയുക'
                        : 'Search by name',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kGreen, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Batch filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: isMalayalam ? 'എല്ലാം' : 'All',
                        selected: _batchId == null,
                        onTap: () => setState(() => _batchId = null),
                      ),
                      ...widget.batches.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: isMalayalam ? b.nameMl : b.name,
                            selected: _batchId == b.id,
                            onTap: () => setState(() => _batchId = b.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (list.isEmpty)
                  EmptyState(
                    icon: Icons.person_search_rounded,
                    title: isMalayalam
                        ? 'വിദ്യാർഥികൾ ഇല്ല'
                        : 'No students found',
                    message: isMalayalam
                        ? 'ഫിൽട്ടർ മാറ്റി വീണ്ടും ശ്രമിക്കുക.'
                        : 'Try changing the filter or search.',
                  )
                else
                  ...list.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StudentCard(
                        student: s,
                        isMalayalam: isMalayalam,
                        onTap: () => widget.onOpenStudent(s),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kGreen : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kBody,
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final TeacherStudent student;
  final bool isMalayalam;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.isMalayalam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logged = student.loggedToday;
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: student.color.withValues(alpha: 0.15),
            child: Text(
              student.avatar,
              style: TextStyle(
                color: student.color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMalayalam ? student.nameMl : student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: kHeading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: logged
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isMalayalam
                      ? '${student.batchNameMl} · ആഴ്ച ${student.weekPct}%'
                      : '${student.batchName} · Week ${student.weekPct}%',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kMuted),
        ],
      ),
    );
  }
}
