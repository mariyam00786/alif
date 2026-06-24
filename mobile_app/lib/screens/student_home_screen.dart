import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../components/portal_ui.dart';
import '../shared/theme/theme.dart';

// Redesigned dashboard palette.
const Color _kGreenDark = AppColors.primaryDeep;

/// Minimal icon badge — soft tinted background with a colored icon.
Widget _iconBadge(
  IconData icon,
  Color color, {
  double size = 42,
  double radius = 13,
  double iconSize = 20,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(icon, size: iconSize, color: color),
  );
}

/// Student Home Dashboard (FRD 4.2.1).
/// Shows a greeting, today's activity status, current streak, weekly points,
/// quick actions and a daily motivational hadith. Pure presentational widget
/// with graceful sample data; navigation is delegated to the parent shell.
class StudentHomeScreen extends StatelessWidget {
  final String studentName;

  /// Switch the bottom-nav to a sibling tab.
  final VoidCallback onMarkToday;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenRanking;
  final VoidCallback onOpenBadges;

  // Sample data (replaced by API once wired).
  final int todayDone;
  final int todayTotal;
  final int todayMarks;
  final int todayMaxMarks;
  final int streakDays;
  final int weekPoints;
  final int batchRank;
  final int batchSize;

  /// Per-day completion for the current week (Mon..Sun). Each entry is a map
  /// with `done` (bool), `is_today` (bool) and `is_future` (bool). Comes from
  /// the backend home-summary so the streak chips reflect real activity.
  final List<dynamic> weekDays;

  /// Real badge progress and a small preview list (each entry has `name`,
  /// `name_ml`, `icon`, `earned`) from the backend home-summary.
  final int badgesEarned;
  final int badgesTotal;
  final List<dynamic> badges;

  /// Whether the backend summary has finished loading. While false the cards
  /// show a neutral resting state instead of misleading zeros.
  final bool summaryLoaded;

  const StudentHomeScreen({
    super.key,
    required this.studentName,
    required this.onMarkToday,
    required this.onOpenProgress,
    required this.onOpenRanking,
    required this.onOpenBadges,
    this.todayDone = 0,
    this.todayTotal = 0,
    this.todayMarks = 0,
    this.todayMaxMarks = 0,
    this.streakDays = 0,
    this.weekPoints = 0,
    this.batchRank = 0,
    this.batchSize = 0,
    this.weekDays = const [],
    this.badgesEarned = 0,
    this.badgesTotal = 0,
    this.badges = const [],
    this.summaryLoaded = false,
  });

  // Rotating Quran verses shown in the hero card.
  static const List<Map<String, String>> _verses = [
    {
      'en': 'And say, "My Lord, increase me in knowledge."',
      'ml': 'പറയുക: "എന്റെ രക്ഷിതാവേ, എനിക്ക് അറിവ് വർദ്ധിപ്പിച്ചു തരേണമേ."',
      'ref': 'Quran 20:114',
    },
    {
      'en': 'Indeed, with hardship comes ease.',
      'ml': 'തീർച്ചയായും പ്രയാസത്തോടൊപ്പം എളുപ്പമുണ്ട്.',
      'ref': 'Quran 94:6',
    },
    {
      'en': 'So remember Me; I will remember you.',
      'ml': 'നിങ്ങൾ എന്നെ ഓർക്കുക; ഞാൻ നിങ്ങളെ ഓർക്കും.',
      'ref': 'Quran 2:152',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final fullName = studentName.trim();
    final verse = _verses[DateTime.now().day % _verses.length];

    return ColoredBox(
      color: kSurface,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 14),
        children: [
          _header(isMalayalam, fullName),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _verseHero(isMalayalam, verse),
                const SizedBox(height: 10),
                _todaysProgress(isMalayalam),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _streakCard(isMalayalam)),
                      const SizedBox(width: 12),
                      Expanded(child: _weekCard(isMalayalam)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _achievementsCard(isMalayalam),
                const SizedBox(height: 10),
                _footerBanner(isMalayalam),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool isMalayalam, String fullName) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
                          fullName,
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
                        ? 'പഠിച്ച്, വളർന്ന്, അല്ലാഹുവിനെ പ്രസാദിപ്പിക്കൂ.'
                        : 'Keep learning, growing and pleasing Allah.',
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
            PortalNotificationBellAsync(
              fallback: const [],
              source: PortalNotificationSource.student,
              isMalayalam: isMalayalam,
              minimal: true,
              size: 44,
            ),
            const SizedBox(width: 10),
            PortalProfileAvatar(
              fallbackName: studentName,
              onDark: false,
              size: 44,
            ),
          ],
        ),
      ),
    );
  }

  // ── Card primitives ───────────────────────────────────────────────────────
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

  // ── Quran verse hero ──────────────────────────────────────────────────────
  Widget _verseHero(bool isMalayalam, Map<String, String> verse) {
    return Container(
      height: 138,
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
              top: 20,
              right: 24,
              child: Icon(
                Icons.nightlight_round,
                size: 26,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Positioned(top: 34, right: 72, child: _star(4)),
            Positioned(top: 18, right: 98, child: _star(3)),
            Positioned(top: 56, right: 52, child: _star(2.5)),
            Positioned(
              right: -8,
              bottom: -18,
              child: Icon(
                Icons.mosque_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\u201C',
                    style: TextStyle(
                      fontSize: 30,
                      height: 0.9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMalayalam ? verse['ml']! : verse['en']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      height: 1.32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    verse['ref']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _star(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  // ── Today's progress (matches the Progress page hero card) ────────────────
  Widget _todaysProgress(bool isMalayalam) {
    final total = todayTotal;
    final done = todayDone.clamp(0, total == 0 ? todayDone : total);
    final marks = todayMarks;
    final maxMarks = todayMaxMarks;
    // Percentage mirrors the Progress page: marks earned ÷ max possible marks.
    final pct = maxMarks > 0
        ? (marks / maxMarks).clamp(0.0, 1.0)
        : (total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0);
    final percentLabel = (pct * 100).round();
    final allDone = total > 0 && done >= total;
    final remaining = (total - done).clamp(0, total);

    String statusText;
    if (!summaryLoaded) {
      statusText = isMalayalam ? 'വിവരങ്ങൾ ലോഡ് ചെയ്യുന്നു…' : 'Loading…';
    } else if (total == 0) {
      statusText = isMalayalam
          ? 'ഇന്ന് മാർക്ക് ചെയ്യാൻ പ്രവർത്തനങ്ങളൊന്നുമില്ല.'
          : 'No activities to mark today.';
    } else if (allDone) {
      statusText = isMalayalam
          ? 'മാഷാ അല്ലാഹ്! ഇന്നത്തെ എല്ലാം പൂർത്തിയായി.'
          : "Masha'Allah! All done for today.";
    } else {
      statusText = isMalayalam
          ? 'ഇനി $remaining പ്രവർത്തനങ്ങൾ ബാക്കിയുണ്ട്.'
          : '$remaining more to complete today.';
    }

    return GestureDetector(
      onTap: onOpenProgress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDeep, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 22,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMalayalam ? 'ഇന്നത്തെ മാർക്ക്' : "Today's marks",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$marks',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            if (maxMarks > 0)
                              TextSpan(
                                text: ' / $maxMarks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$done/$total ${isMalayalam ? 'പ്രവർത്തനങ്ങൾ' : 'activities'}',
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
                  width: 74,
                  height: 74,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: CircularProgressIndicator(
                          value: summaryLoaded ? pct : null,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      Text(
                        '$percentLabel%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  allDone
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                if (summaryLoaded && total > 0 && !allDone) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onMarkToday,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isMalayalam ? 'മാർക്ക് ചെയ്യൂ' : 'Mark now',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Streak card ───────────────────────────────────────────────────────────
  Widget _streakCard(bool isMalayalam) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final value = streakDays;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 19,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isMalayalam ? 'നിലവിലെ സ്ട്രീക്ക്' : 'Current Streak',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kHeading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: kHeading,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isMalayalam ? 'ദിവസം' : 'days',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value > 0
                ? (isMalayalam
                      ? 'തുടരൂ! സ്ഥിരതയാണ് വിജയം.'
                      : 'Keep it up! Consistency builds excellence.')
                : (isMalayalam
                      ? 'ഇന്ന് മാർക്ക് ചെയ്ത് സ്ട്രീക്ക് തുടങ്ങൂ.'
                      : 'Mark today to start your streak.'),
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    _dayChip(
                      labels[i],
                      done: _dayFlag(i, 'done'),
                      isToday: _dayFlag(i, 'is_today'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reads a boolean flag for the i-th weekday (Mon=0..Sun=6) from the real
  /// backend `weekDays` payload. Falls back to false when data is absent.
  bool _dayFlag(int index, String key) {
    if (index < 0 || index >= weekDays.length) return false;
    final entry = weekDays[index];
    if (entry is Map) return entry[key] == true;
    return false;
  }

  Widget _dayChip(String label, {required bool done, required bool isToday}) {
    final circleColor = done ? AppColors.primary : AppColors.neutral200;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: isToday && !done
                ? Border.all(color: AppColors.primary, width: 1.6)
                : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: done
                ? AppColors.primaryDeep
                : (isToday ? AppColors.primary : kMuted),
          ),
        ),
      ],
    );
  }

  // ── This week card ────────────────────────────────────────────────────────
  Widget _weekCard(bool isMalayalam) {
    final hasRank = batchRank > 0;
    return GestureDetector(
      onTap: onOpenRanking,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isMalayalam ? 'ഈ ആഴ്ച' : 'This Week',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kHeading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$weekPoints',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isMalayalam ? 'പോയിന്റ്' : 'points',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isMalayalam ? 'കഴിഞ്ഞ 7 ദിവസം' : 'Earned in last 7 days',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: kMuted,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasRank
                        ? (isMalayalam
                              ? 'ബാച്ചിൽ റാങ്ക് $batchRank${batchSize > 0 ? '/$batchSize' : ''}'
                              : 'Rank $batchRank${batchSize > 0 ? ' of $batchSize' : ''} in batch')
                        : (isMalayalam
                              ? 'റാങ്ക് ഇതുവരെ ലഭ്യമല്ല'
                              : 'Rank not available yet'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kHeading,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Badges & achievements preview ─────────────────────────────────────────
  Widget _achievementsCard(bool isMalayalam) {
    final earnedCount = badgesEarned;
    final total = badgesTotal;
    final hasBadges = badges.isNotEmpty;

    return GestureDetector(
      onTap: onOpenBadges,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(
                  Icons.military_tech_rounded,
                  AppColors.gold,
                  size: 36,
                  radius: 11,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMalayalam
                            ? 'ബാഡ്ജുകൾ & നേട്ടങ്ങൾ'
                            : 'Badges & Achievements',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kHeading,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMalayalam
                            ? '$earnedCount/$total എണ്ണം നേടി · എല്ലാം കാണുക'
                            : '$earnedCount of $total earned · tap to view all',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
            if (hasBadges) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < badges.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _badgeMedallion(badges[i], isMalayalam)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badgeMedallion(dynamic raw, bool isMalayalam) {
    final b = raw is Map ? raw : const <String, dynamic>{};
    final earned = b['earned'] == true;
    final icon = (b['icon'] as String?)?.trim();
    final nameEn = (b['name'] as String?) ?? '';
    final nameMl = (b['name_ml'] as String?) ?? nameEn;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: earned
                ? AppColors.gold.withValues(alpha: 0.14)
                : const Color(0xFFF1F3F5),
            shape: BoxShape.circle,
            border: Border.all(
              color: earned
                  ? AppColors.gold.withValues(alpha: 0.45)
                  : const Color(0xFFE3E6E9),
            ),
          ),
          alignment: Alignment.center,
          child: earned
              ? Text(
                  (icon != null && icon.isNotEmpty) ? icon : '🏅',
                  style: const TextStyle(fontSize: 24),
                )
              : const Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: Color(0xFFB6BCC2),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          isMalayalam ? nameMl : nameEn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: earned ? kHeading : kMuted,
          ),
        ),
      ],
    );
  }

  // ── Motivational footer ───────────────────────────────────────────────────
  Widget _footerBanner(bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(11),
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
                  ? 'ചെറിയ ചുവടുകൾ ഇന്ന്, വലിയ പ്രതിഫലം നാളെ ഇൻ ഷാ അല്ലാഹ്.'
                  : 'Small steps today, big rewards tomorrow insha\u2019Allah.',
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
