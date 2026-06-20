import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../components/portal_ui.dart';

/// Student Badges & Achievements (FRD 4.2.5).
/// Self-view of earned badges, progress toward the next badge and locked
/// badges. Sample data with graceful fallback; embeddable in a shell.
class StudentBadgesScreen extends StatelessWidget {
  /// When true renders without its own Scaffold/header (for embedding).
  final bool embedded;

  const StudentBadgesScreen({super.key, this.embedded = false});

  static const List<Map<String, dynamic>> _badges = [
    {
      'icon': '🌟',
      'name': 'First Steps',
      'nameMl': 'ആദ്യ ചുവടുകൾ',
      'desc': 'Marked your first activity',
      'descMl': 'ആദ്യ പ്രവർത്തനം മാർക്ക് ചെയ്തു',
      'earned': true,
      'date': '12 May',
    },
    {
      'icon': '🔥',
      'name': '7-Day Streak',
      'nameMl': '7 ദിന സ്ട്രീക്ക്',
      'desc': 'Active 7 days in a row',
      'descMl': 'തുടർച്ചയായി 7 ദിവസം സജീവം',
      'earned': true,
      'date': '20 May',
    },
    {
      'icon': '📖',
      'name': 'Quran Reader',
      'nameMl': 'ഖുർആൻ പാരായണം',
      'desc': 'Read Quran 30 days',
      'descMl': '30 ദിവസം ഖുർആൻ പാരായണം',
      'earned': true,
      'date': '2 Jun',
    },
    {
      'icon': '🤝',
      'name': 'Kind Heart',
      'nameMl': 'ദയയുള്ള ഹൃദയം',
      'desc': '20 acts of kindness',
      'descMl': '20 ദയാപ്രവൃത്തികൾ',
      'earned': false,
      'progress': 14,
      'target': 20,
    },
    {
      'icon': '🕌',
      'name': 'Prayer Champion',
      'nameMl': 'നമസ്കാര ചാമ്പ്യൻ',
      'desc': 'All 5 prayers for 30 days',
      'descMl': '30 ദിവസം 5 നേരം നമസ്കാരം',
      'earned': false,
      'progress': 22,
      'target': 30,
    },
    {
      'icon': '🏆',
      'name': 'Top of Batch',
      'nameMl': 'ബാച്ചിലെ ഒന്നാമൻ',
      'desc': 'Rank #1 in your batch',
      'descMl': 'ബാച്ചിൽ ഒന്നാം റാങ്ക്',
      'earned': false,
      'progress': 0,
      'target': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final earned = _badges.where((b) => b['earned'] == true).toList();
    final locked = _badges.where((b) => b['earned'] != true).toList();
    final nextBadge = locked.firstWhere(
      (b) => (b['progress'] as int? ?? 0) > 0,
      orElse: () => locked.isNotEmpty ? locked.first : <String, dynamic>{},
    );

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _summaryCard(isMalayalam, earned.length, _badges.length),
        if (nextBadge.isNotEmpty && (nextBadge['target'] as int? ?? 0) > 0) ...[
          const SizedBox(height: 16),
          SectionLabel(
            isMalayalam ? 'അടുത്ത ബാഡ്ജ്' : 'Next Badge',
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 12),
          _nextBadgeCard(isMalayalam, nextBadge),
        ],
        const SizedBox(height: 20),
        SectionLabel(
          isMalayalam ? 'നേടിയ ബാഡ്ജുകൾ' : 'Earned Badges',
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 12),
        _grid(earned, isMalayalam, earnedGrid: true),
        const SizedBox(height: 20),
        SectionLabel(
          isMalayalam ? 'ലോക്ക് ചെയ്തവ' : 'Locked Badges',
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 12),
        _grid(locked, isMalayalam, earnedGrid: false),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'ബാഡ്ജുകൾ' : 'Badges',
            subtitle: isMalayalam ? 'നിങ്ങളുടെ നേട്ടങ്ങൾ' : 'Your achievements',
            icon: Icons.military_tech_rounded,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _summaryCard(bool isMalayalam, int earned, int total) {
    final pct = total == 0 ? 0.0 : earned / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6B3A), Color(0xFF22965C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text(
                  '$earned',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? 'നേട്ടങ്ങൾ തുറന്നു' : 'Badges Unlocked',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMalayalam
                      ? '$total ൽ $earned എണ്ണം നേടി'
                      : '$earned of $total earned',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextBadgeCard(bool isMalayalam, Map<String, dynamic> b) {
    final progress = b['progress'] as int? ?? 0;
    final target = b['target'] as int? ?? 1;
    final pct = (progress / target).clamp(0.0, 1.0);
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kGreenSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              b['icon'] as String,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? b['nameMl'] as String : b['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kHeading,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: kGreenSoft,
                    valueColor: const AlwaysStoppedAnimation(kGreen),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isMalayalam ? '$target ൽ $progress' : '$progress / $target',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(
    List<Map<String, dynamic>> items,
    bool isMalayalam, {
    required bool earnedGrid,
  }) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.military_tech_rounded,
        title: isMalayalam ? 'ഒന്നുമില്ല' : 'Nothing here',
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: items
          .map((b) => _badgeCard(b, isMalayalam, earnedGrid))
          .toList(),
    );
  }

  Widget _badgeCard(Map<String, dynamic> b, bool isMalayalam, bool earned) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      color: earned ? Colors.white : const Color(0xFFF7F8F9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: earned ? kGreenSoft : const Color(0xFFECEEF0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: earned
                ? Text(
                    b['icon'] as String,
                    style: const TextStyle(fontSize: 30),
                  )
                : const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 26,
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            isMalayalam ? b['nameMl'] as String : b['name'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: earned ? kHeading : kMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isMalayalam ? b['descMl'] as String : b['desc'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: kMuted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (earned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: kGreenSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                b['date'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kGreen,
                ),
              ),
            )
          else
            Text(
              (b['progress'] as int? ?? 0) > 0
                  ? '${b['progress']}/${b['target']}'
                  : (isMalayalam ? 'ലോക്ക്' : 'Locked'),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
            ),
        ],
      ),
    );
  }
}
