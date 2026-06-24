import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../shared/theme/theme.dart';
import 'teacher_data.dart';

/// Dashboard accent shared with the student home.
const Color _kGreenDark = AppColors.primaryDeep;

/// Teacher home — dashboard overview (FRD §4.3.1).
///
/// Shows assigned batches, today's student activity status, students needing
/// attention (low performers) and quick stats. Mirrors the student home's
/// design language: a light greeting header, a teal gradient hero and soft
/// floating white cards.
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _overviewHero(),
                const SizedBox(height: 16),
                _batchesSection(),
                const SizedBox(height: 4),
                _attentionSection(),
                const SizedBox(height: 14),
                _footerBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Light greeting header ─────────────────────────────────────────────────
  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMalayalam ? 'അസ്സലാമു അലൈക്കും,' : 'Assalamu alaikum,',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kBody,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          teacherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _kGreenDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('🌿', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMalayalam
                        ? 'നിങ്ങളുടെ ബാച്ചുകൾ ഇന്ന് എങ്ങനെയെന്ന് നോക്കാം.'
                        : "Here's how your batches are doing today.",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            PortalNotificationBell(
              notifications: TeacherData.notifications(),
              isMalayalam: isMalayalam,
              minimal: true,
              size: 44,
            ),
            const SizedBox(width: 10),
            PortalProfileAvatar(
              fallbackName: teacherName,
              onDark: false,
              size: 44,
            ),
          ],
        ),
      ),
    );
  }

  // ── Card primitives (shared with student home) ────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEFF1F3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // ── Teal gradient overview hero ───────────────────────────────────────────
  Widget _overviewHero() {
    final students = TeacherData.totalStudents;
    final active = TeacherData.activeToday;
    final avg = TeacherData.avgCompletion;
    final pct = (avg / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onOpenStudents,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDeep,
              AppColors.primary,
              AppColors.primaryLight,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -18,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMalayalam ? 'ഇന്നത്തെ സംഗ്രഹം' : "Today's overview",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$avg',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const TextSpan(
                                text: '%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMalayalam
                              ? '$students വിദ്യാർഥികൾ · $active ഇന്ന് സജീവം'
                              : '$students students · $active active today',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.22),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        Text(
                          isMalayalam ? 'ശരാശരി' : 'avg',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── My batches ────────────────────────────────────────────────────────────
  Widget _batchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              decoration: _cardDecoration(),
              onTap: () => onOpenBatch(b),
            ),
          ),
        ),
      ],
    );
  }

  // ── Students needing attention ────────────────────────────────────────────
  Widget _attentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          isMalayalam ? 'ശ്രദ്ധ വേണ്ടവർ' : 'Needs attention',
          icon: Icons.priority_high_rounded,
        ),
        const SizedBox(height: 8),
        if (needsAttention.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: kGreen, size: 22),
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
                decoration: _cardDecoration(),
                onTap: () => onOpenStudent(s),
              ),
            ),
          ),
      ],
    );
  }

  // ── Motivational footer (shared with student home) ────────────────────────
  Widget _footerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_florist_rounded,
            size: 30,
            color: AppColors.primary.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMalayalam
                  ? 'നിങ്ങളുടെ മാർഗനിർദേശം അവരുടെ വളർച്ചയാണ്. ബാറക്കല്ലാഹു ഫീക്.'
                  : 'Your guidance shapes their growth. Barakallahu feek.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 20,
              color: AppColors.gold,
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
  final BoxDecoration decoration;
  final VoidCallback onTap;

  const _BatchCard({
    required this.batch,
    required this.isMalayalam,
    required this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: decoration,
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
                    child: Icon(
                      Icons.class_rounded,
                      color: batch.color,
                      size: 24,
                    ),
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
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final TeacherStudent student;
  final bool isMalayalam;
  final BoxDecoration decoration;
  final VoidCallback onTap;

  const _AttentionCard({
    required this.student,
    required this.isMalayalam,
    required this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reason = !student.loggedToday
        ? (isMalayalam ? 'ഇന്ന് ലോഗ് ചെയ്തിട്ടില്ല' : 'No log today')
        : (isMalayalam ? 'കുറഞ്ഞ ആഴ്ച പ്രകടനം' : 'Low weekly score');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: decoration,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        ),
      ),
    );
  }
}
