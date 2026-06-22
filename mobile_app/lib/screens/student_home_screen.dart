import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../components/portal_ui.dart';
import '../shared/theme/theme.dart';

// Redesigned dashboard palette.
const Color _kGreenDark = AppColors.primaryDeep;

/// How far the Today's Activities card overlaps below the colored top section.
/// The card straddles the boundary — roughly half over the primary color and
/// half below it.
const double _kCardOverlap = 60;

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
  final int streakDays;
  final int weekPoints;
  final int batchRank;

  const StudentHomeScreen({
    super.key,
    required this.studentName,
    required this.onMarkToday,
    required this.onOpenProgress,
    required this.onOpenRanking,
    required this.onOpenBadges,
    this.todayDone = 6,
    this.todayTotal = 9,
    this.streakDays = 7,
    this.weekPoints = 210,
    this.batchRank = 3,
  });

  /// Demo notifications surfaced in the home header bell (replaced by the API
  /// once wired). Shared with the student progress screen so both headers show
  /// the same list.
  static const List<PortalNotification> demoNotifications = [
    PortalNotification(
      title: 'New badge earned',
      titleMl: 'പുതിയ ബാഡ്ജ് നേടി',
      body: 'You earned the "Prayer Master" badge. Keep it up!',
      bodyMl: 'നിങ്ങൾ "നമസ്കാര വിജയി" ബാഡ്ജ് നേടി. തുടരുക!',
      timeAgo: '2 hours ago',
      timeAgoMl: '2 മണിക്കൂർ മുമ്പ്',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF8B5CF6),
      unread: true,
    ),
    PortalNotification(
      title: 'Today\'s marking pending',
      titleMl: 'ഇന്നത്തെ മാർക്കിംഗ് ബാക്കി',
      body: 'You haven\'t completed today\'s activity marking yet.',
      bodyMl: 'ഇന്നത്തെ പ്രവർത്തന മാർക്കിംഗ് ഇതുവരെ പൂർത്തിയായില്ല.',
      timeAgo: '4 hours ago',
      timeAgoMl: '4 മണിക്കൂർ മുമ്പ്',
      icon: Icons.checklist_rounded,
      color: Color(0xFFF59E0B),
      unread: true,
    ),
    PortalNotification(
      title: 'You moved up to rank 3',
      titleMl: 'നിങ്ങൾ റാങ്ക് 3 ലേക്ക് ഉയർന്നു',
      body: 'Great work! You climbed up in your batch leaderboard.',
      bodyMl: 'മികച്ച പ്രകടനം! ബാച്ച് ലീഡർബോർഡിൽ നിങ്ങൾ ഉയർന്നു.',
      timeAgo: 'Yesterday',
      timeAgoMl: 'ഇന്നലെ',
      icon: Icons.leaderboard_rounded,
      color: kGreen,
      unread: false,
    ),
    PortalNotification(
      title: 'Holiday notice',
      titleMl: 'അവധി അറിയിപ്പ്',
      body: 'The school will remain closed this Friday.',
      bodyMl: 'ഈ വെള്ളിയാഴ്ച സ്കൂൾ അവധിയായിരിക്കും.',
      timeAgo: '2 days ago',
      timeAgoMl: '2 ദിവസം മുമ്പ്',
      icon: Icons.campaign_rounded,
      color: Color(0xFF3B82F6),
      unread: false,
    ),
  ];

  // A small rotating set of daily reminders.
  static const List<Map<String, String>> _hadiths = [
    {
      'en':
          'The most beloved deeds to Allah are those done regularly, even if small.',
      'ml':
          'അല്ലാഹുവിന് ഏറ്റവും പ്രിയപ്പെട്ട കർമ്മങ്ങൾ ചെറുതാണെങ്കിലും '
          'സ്ഥിരമായി ചെയ്യുന്നവയാണ്.',
      'ref': 'Bukhari & Muslim',
    },
    {
      'en': 'The best of you are those who learn the Quran and teach it.',
      'ml':
          'ഖുർആൻ പഠിക്കുകയും പഠിപ്പിക്കുകയും ചെയ്യുന്നവരാണ് '
          'നിങ്ങളിൽ ഉത്തമർ.',
      'ref': 'Bukhari',
    },
    {
      'en':
          'Kindness is a mark of faith, and whoever is not kind has no faith.',
      'ml':
          'ദയ വിശ്വാസത്തിന്റെ അടയാളമാണ്; ദയയില്ലാത്തവന് '
          'വിശ്വാസമില്ല.',
      'ref': 'Muslim',
    },
  ];

  String _greeting(bool isMalayalam) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isMalayalam ? 'സുപ്രഭാതം' : 'Good morning';
    if (hour < 17) return isMalayalam ? 'ഉച്ചവന്ദനം' : 'Good afternoon';
    return isMalayalam ? 'ശുഭ സായാഹ്നം' : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final fullName = studentName.trim();
    final hadith = _hadiths[DateTime.now().day % _hadiths.length];
    final pending = (todayTotal - todayDone).clamp(0, todayTotal);

    return ColoredBox(
      color: kSurface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(isMalayalam, fullName, pending),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, _kCardOverlap + 18, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Stats row ----
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          value: '$streakDays',
                          label: isMalayalam ? 'ദിന സ്ട്രീക്ക്' : 'Day streak',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          icon: Icons.star_rounded,
                          iconColor: _kGreenDark,
                          value: '$weekPoints',
                          label: isMalayalam
                              ? 'ഈ ആഴ്ച പോയിന്റ്'
                              : 'Points this week',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          value: '#$batchRank',
                          label: isMalayalam ? 'ബാച്ച് റാങ്ക്' : 'Batch rank',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ---- Quick actions ----
                _sectionTitle(
                  isMalayalam ? 'വേഗ പ്രവർത്തനങ്ങൾ' : 'Quick Actions',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _quickAction(
                        icon: Icons.fact_check_rounded,
                        iconColor: const Color(0xFF0F766E),
                        label: isMalayalam
                            ? 'ഇന്ന് മാർക്ക് ചെയ്യുക'
                            : 'Mark today',
                        sub: pending == 0
                            ? (isMalayalam ? 'പൂർത്തിയായി' : 'All done')
                            : (isMalayalam
                                  ? '$pending ബാക്കി'
                                  : '$pending pending'),
                        onTap: onMarkToday,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.insights_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        label: isMalayalam ? 'പുരോഗതി' : 'Progress',
                        sub: isMalayalam ? 'ഈ ആഴ്ച' : 'This week',
                        onTap: onOpenProgress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _quickAction(
                        icon: Icons.leaderboard_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: isMalayalam ? 'റാങ്കിംഗ്' : 'Ranking',
                        sub: isMalayalam
                            ? 'ബാച്ച് #$batchRank'
                            : 'Batch #$batchRank',
                        onTap: onOpenRanking,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.workspace_premium_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        label: isMalayalam ? 'ബാഡ്ജുകൾ' : 'Badges',
                        sub: isMalayalam ? 'നേടിയവ കാണുക' : 'View earned',
                        onTap: onOpenBadges,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ---- Today's reminder ----
                _sectionTitle(
                  isMalayalam ? 'ഇന്നത്തെ ഓർമ്മപ്പെടുത്തൽ' : "Today's Reminder",
                ),
                _reminderCard(isMalayalam, hadith),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool isMalayalam, String fullName, int pending) {
    final pct = todayTotal == 0 ? 0.0 : todayDone / todayTotal;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Colored top section — uses the app primary color.
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDeep,
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, _kCardOverlap + 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting(isMalayalam)},',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isMalayalam
                              ? 'അസ്സലാമു അലൈക്കും, $fullName 👋'
                              : 'Assalamu Alaikum, $fullName 👋',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  PortalNotificationBell(
                    notifications: demoNotifications,
                    isMalayalam: isMalayalam,
                    onDark: true,
                    size: 42,
                  ),
                  const SizedBox(width: 8),
                  PortalProfileAvatar(
                    fallbackName: studentName,
                    onDark: true,
                    size: 42,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Today's Activities card — overlaps from the middle of the colored
        // section (half over the primary color, half below) with a soft
        // primary-tinted shadow.
        Positioned(
          left: 16,
          right: 16,
          bottom: -_kCardOverlap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 26,
                  spreadRadius: -4,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: kGreen.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(kGreen),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$todayDone/$todayTotal',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _kGreenDark,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isMalayalam ? 'കഴിഞ്ഞു' : 'done',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: kMuted,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMalayalam
                            ? 'ഇന്നത്തെ പ്രവർത്തനങ്ങൾ'
                            : "Today's Activities",
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: kHeading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pending == 0
                            ? (isMalayalam
                                  ? 'എല്ലാം പൂർത്തിയായി! 🎉'
                                  : 'All done! 🎉')
                            : (isMalayalam
                                  ? '$pending പ്രവർത്തനങ്ങൾ ബാക്കിയുണ്ട്'
                                  : '$pending activities left to mark'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _TapScale(
                          onTap: onMarkToday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDeep,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: kGreen.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  pending == 0
                                      ? Icons.visibility_rounded
                                      : Icons.edit_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  pending == 0
                                      ? (isMalayalam ? 'കാണുക' : 'Review')
                                      : (isMalayalam
                                            ? 'മാർക്ക് ചെയ്യുക'
                                            : 'Mark now'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: kMuted,
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(icon, iconColor, size: 34, radius: 11, iconSize: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.statNumber.copyWith(fontSize: 19),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.card(),
        child: Row(
          children: [
            _iconBadge(icon, iconColor, size: 46, radius: 15, iconSize: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: const Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderCard(bool isMalayalam, Map<String, String> hadith) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF8E1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4A017).withValues(alpha: 0.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _iconBadge(
              Icons.auto_stories_rounded,
              const Color(0xFFD4A017),
              size: 36,
              radius: 11,
              iconSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? hadith['ml']! : hadith['en']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF444444),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '— ${hadith['ref']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB8860B),
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

/// Small wrapper that scales its child to 0.97 while pressed, then runs [onTap].
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
