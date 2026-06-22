import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../components/portal_ui.dart';

// Redesigned dashboard palette.
const Color _kGreenDark = Color(0xFF1B6B3A);

// Darkened muted for better WCAG AA contrast (≥4.5:1 on white).
const Color _kLabelGray = Color(0xFF6B7280);

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
    final firstName = studentName.trim().split(' ').first;
    final hadith = _hadiths[DateTime.now().day % _hadiths.length];
    final pending = (todayTotal - todayDone).clamp(0, todayTotal);

    return Column(
      children: [
        _header(isMalayalam, firstName, pending),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
              const SizedBox(height: 14),
              // ---- Quick actions ----
              _sectionTitle(
                isMalayalam ? 'വേഗ പ്രവർത്തനങ്ങൾ' : 'Quick Actions',
              ),
              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      icon: Icons.check_box_rounded,
                      iconBg: const Color(0xFFE8F8F0),
                      iconColor: const Color(0xFF1B6B3A),
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
                      icon: Icons.trending_up_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF3B82F6),
                      label: isMalayalam ? 'പുരോഗതി' : 'Progress',
                      sub: isMalayalam ? 'ഈ ആഴ്ച' : 'This week',
                      onTap: onOpenProgress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      icon: Icons.bar_chart_rounded,
                      iconBg: const Color(0xFFFEF3E2),
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
                      iconBg: const Color(0xFFF3F0FF),
                      iconColor: const Color(0xFF7C3AED),
                      label: isMalayalam ? 'ബാഡ്ജുകൾ' : 'Badges',
                      sub: isMalayalam ? 'നേടിയവ കാണുക' : 'View earned',
                      onTap: onOpenBadges,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ---- Today's reminder ----
              _sectionTitle(
                isMalayalam ? 'ഇന്നത്തെ ഓർമ്മപ്പെടുത്തൽ' : "Today's Reminder",
              ),
              _reminderCard(isMalayalam, hadith),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(bool isMalayalam, String firstName, int pending) {
    final pct = todayTotal == 0 ? 0.0 : todayDone / todayTotal;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134D2A), Color(0xFF1B7A3E), Color(0xFF22965C)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x301B6B3A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portal identity badge.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.badge_rounded,
                      size: 12.5,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (isMalayalam ? 'വിദ്യാർത്ഥി പോർട്ടൽ' : 'Student Portal')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Greeting + bell + avatar.
              Row(
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
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMalayalam
                              ? 'അസ്സലാമു അലൈകും, $firstName 👋'
                              : 'Assalamu Alaikum, $firstName 👋',
                          maxLines: 1,
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
                    size: 42,
                  ),
                  const SizedBox(width: 8),
                  PortalProfileAvatar(fallbackName: studentName, size: 42),
                ],
              ),
              const SizedBox(height: 16),
              // Activity progress card inside the header.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 4.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$todayDone/$todayTotal',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                isMalayalam ? 'കഴിഞ്ഞു' : 'done',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.65),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pending == 0
                                ? (isMalayalam
                                      ? 'എല്ലാം പൂർത്തിയായി! 🎉'
                                      : 'All done! 🎉')
                                : (isMalayalam
                                      ? '$pending പ്രവർത്തനങ്ങൾ ബാക്കിയുണ്ട്'
                                      : '$pending activities left to mark'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                onTap: onMarkToday,
                                borderRadius: BorderRadius.circular(22),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: _kGreenDark,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        pending == 0
                                            ? (isMalayalam ? 'കാണുക' : 'Review')
                                            : (isMalayalam
                                                  ? 'മാർക്ക് ചെയ്യുക'
                                                  : 'Mark now'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _kGreenDark,
                                        ),
                                      ),
                                    ],
                                  ),
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
            ],
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kHeading,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kLabelGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _kLabelGray,
                    ),
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
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 16,
              color: Color(0xFFD4A017),
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
