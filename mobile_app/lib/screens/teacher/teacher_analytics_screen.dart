import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../services/teacher_api_service.dart';
import 'teacher_data.dart';

/// Batch analytics for a teacher (FRD §4.3.3).
///
/// Batch-wise completion rates, top performers, areas needing improvement and
/// a comparative view across the teacher's batches.
class TeacherAnalyticsScreen extends StatefulWidget {
  final bool isMalayalam;
  final List<TeacherBatch> batches;
  final List<TeacherStudent> students;

  const TeacherAnalyticsScreen({
    super.key,
    required this.isMalayalam,
    required this.batches,
    required this.students,
  });

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  int _batchIndex = 0;
  final Map<String, TeacherBatchAnalytics> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  /// Fetches live analytics for the selected batch (no-op in demo mode).
  Future<void> _loadAnalytics() async {
    if (widget.batches.isEmpty) return;
    final batch = widget.batches[_batchIndex];
    if (_analytics.containsKey(batch.id)) return;
    final data = await TeacherApiService.fetchBatchAnalytics(batch.id);
    if (!mounted || data == null) return;
    setState(() => _analytics[batch.id] = data);
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;
    final batch = widget.batches.isEmpty ? null : widget.batches[_batchIndex];

    final batchStudents = batch == null
        ? <TeacherStudent>[]
        : (widget.students.where((s) => s.batchId == batch.id).toList()
            ..sort((a, b) => b.weekPct.compareTo(a.weekPct)));
    final topPerformers = batchStudents.take(3).toList();

    // Areas needing improvement = lowest category averages (live when available).
    final live = batch == null ? null : _analytics[batch.id];
    final areas = (live != null && live.areasToImprove.isNotEmpty)
        ? ([...live.areasToImprove]..sort((a, b) => a.pct.compareTo(b.pct)))
        : ([...TeacherData.batchCategories]..sort((a, b) => a.pct.compareTo(b.pct)));

    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'വിശകലനം' : 'Analytics',
            subtitle: isMalayalam
                ? 'ബാച്ച് പ്രകടനവും താരതമ്യവും'
                : 'Batch performance & comparison',
            icon: Icons.insights_rounded,
          ),
          Expanded(
            child: batch == null
                ? EmptyState(
                    icon: Icons.insights_rounded,
                    title: isMalayalam ? 'ബാച്ചുകൾ ഇല്ല' : 'No batches',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      // Batch selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(widget.batches.length, (i) {
                            final b = widget.batches[i];
                            final selected = i == _batchIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _batchIndex = i);
                                  _loadAnalytics();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected ? kGreen : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? kGreen : kBorder,
                                    ),
                                  ),
                                  child: Text(
                                    isMalayalam ? b.nameMl : b.name,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : kBody,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Completion rate cards
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              icon: Icons.groups_rounded,
                              value: '${batch.studentCount}',
                              label: isMalayalam ? 'വിദ്യാർഥികൾ' : 'Students',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              icon: Icons.bolt_rounded,
                              value: '${batch.activeToday}',
                              label: isMalayalam ? 'ഇന്ന് സജീവം' : 'Active',
                              tint: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              icon: Icons.percent_rounded,
                              value: '${batch.avgCompletion}%',
                              label: isMalayalam ? 'പൂർത്തീകരണം' : 'Completion',
                              tint: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Top performers
                      SectionLabel(
                        isMalayalam ? 'മികച്ച പ്രകടനം' : 'Top performers',
                        icon: Icons.military_tech_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (topPerformers.isEmpty)
                        SoftCard(
                          child: Text(
                            isMalayalam ? 'ഡാറ്റ ഇല്ല' : 'No data',
                            style: const TextStyle(color: kMuted),
                          ),
                        )
                      else
                        ...topPerformers.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PerformerRow(
                              rank: e.key + 1,
                              student: e.value,
                              isMalayalam: isMalayalam,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Areas needing improvement
                      SectionLabel(
                        isMalayalam
                            ? 'മെച്ചപ്പെടേണ്ട മേഖലകൾ'
                            : 'Areas to improve',
                        icon: Icons.trending_down_rounded,
                      ),
                      const SizedBox(height: 10),
                      ...areas.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AreaRow(category: c, isMalayalam: isMalayalam),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Comparative analysis across batches
                      SectionLabel(
                        isMalayalam ? 'ബാച്ച് താരതമ്യം' : 'Batch comparison',
                        icon: Icons.bar_chart_rounded,
                      ),
                      const SizedBox(height: 10),
                      SoftCard(
                        child: Column(
                          children: widget.batches
                              .map(
                                (b) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 7,
                                  ),
                                  child: _ComparisonRow(
                                    batch: b,
                                    isMalayalam: isMalayalam,
                                    highlight: b.id == batch.id,
                                  ),
                                ),
                              )
                              .toList(),
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

class _PerformerRow extends StatelessWidget {
  final int rank;
  final TeacherStudent student;
  final bool isMalayalam;

  const _PerformerRow({
    required this.rank,
    required this.student,
    required this.isMalayalam,
  });

  @override
  Widget build(BuildContext context) {
    const medals = [Color(0xFFFFA000), Color(0xFF9CA3AF), Color(0xFFB45309)];
    final medal = rank <= 3 ? medals[rank - 1] : kMuted;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: medal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: medal,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMalayalam ? student.nameMl : student.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kHeading,
              ),
            ),
          ),
          Text(
            '${student.weekPct}%',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  final CategoryScore category;
  final bool isMalayalam;

  const _AreaRow({required this.category, required this.isMalayalam});

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

class _ComparisonRow extends StatelessWidget {
  final TeacherBatch batch;
  final bool isMalayalam;
  final bool highlight;

  const _ComparisonRow({
    required this.batch,
    required this.isMalayalam,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            isMalayalam ? batch.nameMl : batch.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? kGreen : kBody,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: batch.avgCompletion / 100,
              minHeight: 9,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(
                highlight ? kGreen : batch.color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${batch.avgCompletion}%',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: kHeading,
          ),
        ),
      ],
    );
  }
}
