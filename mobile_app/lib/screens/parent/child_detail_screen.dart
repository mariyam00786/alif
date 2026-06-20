import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../components/portal_ui.dart';
import '../dashboard/student_dashboard_screen.dart';
import 'child_achievements_view.dart';
import 'child_leaderboard_view.dart';
import 'child_progress_view.dart';
import 'child_remarks_view.dart';
import 'parent_data.dart';

/// Per-child detail for parents: Progress / Ranking / Achievements.
///
/// Uses the live [ChildProgressView], [ChildLeaderboardView] and
/// [ChildAchievementsView] (all backed by the parent API) under a single
/// child-context header.
class ChildDetailScreen extends StatefulWidget {
  final ParentChild child;
  final bool isMalayalam;
  final VoidCallback onBack;

  const ChildDetailScreen({
    super.key,
    required this.child,
    required this.isMalayalam,
    required this.onBack,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  int _tab = 0;

  /// Opens the child's full student board (the same board the student sees)
  /// in a parent-viewing mode with a back action.
  void _openStudentBoard(ParentChild c) {
    final appState = context.appState;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MobileStudentDashboard(
          locale: appState.locale,
          onLocaleChanged: appState.setLocale,
          onLogout: () => Navigator.of(context).maybePop(),
          onExit: () => Navigator.of(context).maybePop(),
          studentId: c.id,
          studentName: widget.isMalayalam ? c.nameMl : c.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.child;
    final isMalayalam = widget.isMalayalam;

    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          _header(c, isMalayalam),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                ChildProgressView(childId: c.id, isMalayalam: isMalayalam),
                ChildLeaderboardView(childId: c.id, isMalayalam: isMalayalam),
                ChildAchievementsView(childId: c.id, isMalayalam: isMalayalam),
                ChildRemarksView(childId: c.id, isMalayalam: isMalayalam),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(ParentChild c, bool isMalayalam) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6B3A), Color(0xFF22965C)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x332D5A34),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    tooltip: isMalayalam ? 'തിരികെ' : 'Back',
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.avatar,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMalayalam ? c.nameMl : c.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isMalayalam ? c.batchNameMl : c.batchName} · ${isMalayalam ? 'റാങ്ക്' : 'Rank'} #${c.rank}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StudentBoardButton(
                isMalayalam: isMalayalam,
                onTap: () => _openStudentBoard(c),
              ),
              const SizedBox(height: 16),
              PortalSegmented(
                onHeader: true,
                index: _tab,
                items: isMalayalam
                    ? const ['പുരോഗതി', 'റാങ്ക്', 'നേട്ടം', 'കുറിപ്പ്']
                    : const ['Progress', 'Ranking', 'Badges', 'Remarks'],
                onChanged: (i) => setState(() => _tab = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width call-to-action that opens the child's full student board.
class _StudentBoardButton extends StatelessWidget {
  final bool isMalayalam;
  final VoidCallback onTap;

  const _StudentBoardButton({required this.isMalayalam, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam ? 'സ്റ്റുഡന്റ് ബോർഡ്' : 'Student Board',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isMalayalam
                          ? 'കുട്ടി കാണുന്ന മുഴുവൻ ബോർഡ് തുറക്കുക'
                          : "Open the full board your child sees",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
