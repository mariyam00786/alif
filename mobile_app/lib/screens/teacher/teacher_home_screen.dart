import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import 'teacher_data.dart';

/// Teacher home — dashboard overview (FRD §4.3.1).
///
/// Shows assigned batches, today's student activity status, students needing
/// attention (low performers) and quick stats.
class TeacherHomeScreen extends StatelessWidget {
  final bool isMalayalam;
  final String teacherName;
  final List<TeacherBatch> batches;
  final List<TeacherStudent> needsAttention;
  final ValueChanged<TeacherBatch> onOpenBatch;
  final ValueChanged<TeacherStudent> onOpenStudent;
  final VoidCallback onOpenStudents;

  const TeacherHomeScreen({
    super.key,
    required this.isMalayalam,
    required this.teacherName,
    required this.batches,
    required this.needsAttention,
    required this.onOpenBatch,
    required this.onOpenStudent,
    required this.onOpenStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'നമസ്കാരം' : 'Welcome',
            subtitle: teacherName,
            icon: Icons.co_present_rounded,
            portalLabel: isMalayalam ? 'ടീച്ചർ പോർട്ടൽ' : 'Teacher Portal',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PortalNotificationBell(
                  notifications: TeacherData.notifications(),
                  isMalayalam: isMalayalam,
                ),
                const SizedBox(width: 10),
                PortalProfileAvatar(fallbackName: teacherName),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // Quick stats
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.groups_rounded,
                        value: '${TeacherData.totalStudents}',
                        label: isMalayalam ? 'വിദ്യാർഥികൾ' : 'Students',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.bolt_rounded,
                        value: '${TeacherData.activeToday}',
                        label: isMalayalam ? 'ഇന്ന് സജീവം' : 'Active today',
                        tint: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.percent_rounded,
                        value: '${TeacherData.avgCompletion}%',
                        label: isMalayalam ? 'ശരാശരി' : 'Avg done',
                        tint: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Assigned batches
                Row(
                  children: [
                    Expanded(
                      child: SectionLabel(
                        isMalayalam ? 'എന്റെ ബാച്ചുകൾ' : 'My batches',
                        icon: Icons.class_rounded,
                      ),
                    ),
                    TextButton(
                      onPressed: onOpenStudents,
                      child: Text(
                        isMalayalam ? 'എല്ലാം' : 'View all',
                        style: const TextStyle(
                          color: kGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...batches.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BatchCard(
                      batch: b,
                      isMalayalam: isMalayalam,
                      onTap: () => onOpenBatch(b),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Students needing attention
                SectionLabel(
                  isMalayalam ? 'ശ്രദ്ധ വേണ്ടവർ' : 'Needs attention',
                  icon: Icons.priority_high_rounded,
                ),
                const SizedBox(height: 8),
                if (needsAttention.isEmpty)
                  SoftCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: kGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isMalayalam
                                ? 'എല്ലാ വിദ്യാർഥികളും ട്രാക്കിലാണ്.'
                                : 'All students are on track.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...needsAttention.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AttentionCard(
                        student: s,
                        isMalayalam: isMalayalam,
                        onTap: () => onOpenStudent(s),
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

class _BatchCard extends StatelessWidget {
  final TeacherBatch batch;
  final bool isMalayalam;
  final VoidCallback onTap;

  const _BatchCard({
    required this.batch,
    required this.isMalayalam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: batch.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.class_rounded, color: batch.color, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam ? batch.nameMl : batch.name,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: kHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMalayalam
                          ? '${batch.studentCount} വിദ്യാർഥികൾ · ${batch.activeToday} ഇന്ന് സജീവം'
                          : '${batch.studentCount} students · ${batch.activeToday} active today',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${batch.avgCompletion}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: batch.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: batch.avgCompletion / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(batch.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final TeacherStudent student;
  final bool isMalayalam;
  final VoidCallback onTap;

  const _AttentionCard({
    required this.student,
    required this.isMalayalam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reason = !student.loggedToday
        ? (isMalayalam ? 'ഇന്ന് ലോഗ് ചെയ്തിട്ടില്ല' : 'No log today')
        : (isMalayalam ? 'കുറഞ്ഞ ആഴ്ച പ്രകടനം' : 'Low weekly score');
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
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
                Text(
                  isMalayalam ? student.nameMl : student.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: kHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isMalayalam ? student.batchNameMl : student.batchName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
