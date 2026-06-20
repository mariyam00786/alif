import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../services/teacher_api_service.dart';
import 'teacher_data.dart';

/// Individual student progress + remarks for a teacher (FRD §4.3.2).
///
/// Shows weekly / monthly performance, a category breakdown and lets the
/// teacher add a remark / feedback note for the student.
class TeacherStudentDetailScreen extends StatefulWidget {
  final bool isMalayalam;
  final TeacherStudent student;
  final VoidCallback onBack;

  const TeacherStudentDetailScreen({
    super.key,
    required this.isMalayalam,
    required this.student,
    required this.onBack,
  });

  @override
  State<TeacherStudentDetailScreen> createState() =>
      _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState
    extends State<TeacherStudentDetailScreen> {
  int _period = 0; // 0 = weekly, 1 = monthly
  late List<StudentRemark> _remarks = TeacherData.remarksForStudent(
    widget.student.id,
  );
  List<CategoryScore> _categories = TeacherData.studentCategories;
  int? _livePct; // live completion % for the selected period, when available

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  /// Fetches live progress for the current period; falls back to demo data.
  Future<void> _loadProgress() async {
    final progress = await TeacherApiService.fetchStudentProgress(
      widget.student.id,
      monthly: _period == 1,
    );
    if (!mounted || progress == null) return;
    setState(() {
      _livePct = progress.completionPct;
      if (progress.categories.isNotEmpty) _categories = progress.categories;
      _remarks = progress.remarks;
    });
  }

  void _onPeriodChanged(int i) {
    setState(() => _period = i);
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;
    final s = widget.student;
    final periodPct = _livePct ?? (_period == 0 ? s.weekPct : s.monthPct);

    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? s.nameMl : s.name,
            subtitle: isMalayalam ? s.batchNameMl : s.batchName,
            icon: Icons.person_rounded,
            trailing: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: isMalayalam ? 'അടയ്ക്കുക' : 'Close',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                // Quick stats
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.today_rounded,
                        value: '${s.todayPct}%',
                        label: isMalayalam ? 'ഇന്ന്' : 'Today',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.leaderboard_rounded,
                        value: '#${s.rank}',
                        label: isMalayalam ? 'റാങ്ക്' : 'Rank',
                        tint: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.emoji_events_rounded,
                        value: '${s.badges}',
                        label: isMalayalam ? 'ബാഡ്ജുകൾ' : 'Badges',
                        tint: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Period toggle
                PortalSegmented(
                  items: isMalayalam
                      ? const ['ആഴ്ച', 'മാസം']
                      : const ['Weekly', 'Monthly'],
                  index: _period,
                  onChanged: _onPeriodChanged,
                ),
                const SizedBox(height: 16),

                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isMalayalam ? 'പൂർത്തീകരണം' : 'Completion',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kBody,
                            ),
                          ),
                          Text(
                            '$periodPct%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: kGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: periodPct / 100,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation(kGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category breakdown
                SectionLabel(
                  isMalayalam ? 'വിഭാഗം അനുസരിച്ച്' : 'By category',
                  icon: Icons.donut_small_rounded,
                ),
                const SizedBox(height: 10),
                ..._categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryRow(category: c, isMalayalam: isMalayalam),
                  ),
                ),
                const SizedBox(height: 12),

                // Remarks
                Row(
                  children: [
                    Expanded(
                      child: SectionLabel(
                        isMalayalam ? 'അഭിപ്രായങ്ങൾ' : 'Remarks',
                        icon: Icons.rate_review_rounded,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addRemark,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(isMalayalam ? 'ചേർക്കുക' : 'Add'),
                      style: TextButton.styleFrom(foregroundColor: kGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_remarks.isEmpty)
                  SoftCard(
                    child: Text(
                      isMalayalam
                          ? 'ഇതുവരെ അഭിപ്രായങ്ങൾ ഇല്ല. ആദ്യത്തേത് ചേർക്കുക.'
                          : 'No remarks yet. Add the first one.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: kMuted,
                      ),
                    ),
                  )
                else
                  ..._remarks.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RemarkCard(remark: r, isMalayalam: isMalayalam),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addRemark() async {
    final isMalayalam = widget.isMalayalam;
    final controller = TextEditingController();
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isMalayalam ? 'അഭിപ്രായം ചേർക്കുക' : 'Add remark',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kHeading,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: isMalayalam
                      ? 'വിദ്യാർഥിക്കുള്ള ഫീഡ്ബാക്ക്...'
                      : 'Feedback for the student...',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isMalayalam ? 'സംരക്ഷിക്കുക' : 'Save remark',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (message == null || message.isEmpty || !mounted) return;

    // Persist via the API when live; otherwise keep a local optimistic entry.
    final saved = await TeacherApiService.addRemark(widget.student.id, message);
    if (!mounted) return;
    final remark =
        saved ??
        StudentRemark(
          id: 'remark-${DateTime.now().millisecondsSinceEpoch}',
          studentId: widget.student.id,
          message: message,
          dateLabel: isMalayalam ? 'ഇപ്പോൾ' : 'Just now',
          dateLabelMl: 'ഇപ്പോൾ',
        );
    setState(() {
      _remarks = [remark, ..._remarks];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isMalayalam ? 'അഭിപ്രായം ചേർത്തു' : 'Remark added'),
        backgroundColor: kGreen,
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryScore category;
  final bool isMalayalam;

  const _CategoryRow({required this.category, required this.isMalayalam});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(category.icon, color: category.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? category.titleMl : category.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: kHeading,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: category.pct / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(category.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${category.pct}%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemarkCard extends StatelessWidget {
  final StudentRemark remark;
  final bool isMalayalam;

  const _RemarkCard({required this.remark, required this.isMalayalam});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            remark.message,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: kBody,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: kMuted),
              const SizedBox(width: 5),
              Text(
                isMalayalam ? remark.dateLabelMl : remark.dateLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
