import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../components/portal_ui.dart';
import '../shared/theme/theme.dart';

/// Student progress view with daily, weekly and monthly summaries.
class ProgressViewScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  /// When true, the screen renders without its own Scaffold / green header so
  /// it can be embedded inside another shell (e.g. the parent child detail).
  final bool embedded;

  const ProgressViewScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.embedded = false,
  });

  @override
  State<ProgressViewScreen> createState() => _ProgressViewScreenState();
}

class _ProgressViewScreenState extends State<ProgressViewScreen> {
  int _tab = 0; // 0=Daily, 1=Weekly, 2=Monthly

  final List<Map<String, dynamic>> _daily = [
    {
      'date': 'Today',
      'dateML': 'ഇന്ന്',
      'marks': 32,
      'pct': 95,
      'done': 9,
      'total': 9,
      'trend': 'up',
    },
    {
      'date': 'Yesterday',
      'dateML': 'ഇന്നലെ',
      'marks': 28,
      'pct': 89,
      'done': 8,
      'total': 9,
      'trend': 'flat',
    },
    {
      'date': 'Mon',
      'dateML': 'തിങ്കൾ',
      'marks': 24,
      'pct': 78,
      'done': 7,
      'total': 9,
      'trend': 'down',
    },
    {
      'date': 'Sun',
      'dateML': 'ഞായർ',
      'marks': 30,
      'pct': 90,
      'done': 8,
      'total': 9,
      'trend': 'up',
    },
  ];

  final Map<String, dynamic> _weekly = {
    'totalMarks': 210,
    'avg': 30,
    'pct': 92,
    'best': 32,
    'done': 63,
    'total': 70,
  };

  final Map<String, dynamic> _monthly = {
    'totalMarks': 850,
    'avg': 27,
    'pct': 88,
    'best': 32,
    'improve': 12,
    'days': 31,
  };

  static const List<PortalNotification> _studentNotifications = [
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

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;

    final segItems = isMalayalam
        ? const ['ദിനം', 'ആഴ്ച', 'മാസം']
        : const ['Daily', 'Weekly', 'Monthly'];

    final body = Column(
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: PortalSegmented(
              index: _tab,
              items: segItems,
              onChanged: (i) => setState(() => _tab = i),
            ),
          )
        else
          PortalHeader(
            title: isMalayalam ? 'പുരോഗതി' : 'Progress',
            subtitle: widget.studentName,
            icon: Icons.insights_rounded,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PortalNotificationBell(
                  notifications: _studentNotifications,
                  isMalayalam: isMalayalam,
                ),
                const SizedBox(width: 10),
                PortalProfileAvatar(fallbackName: widget.studentName),
              ],
            ),
            bottom: PortalSegmented(
              onHeader: true,
              index: _tab,
              items: segItems,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              _dailyView(isMalayalam),
              _weeklyView(isMalayalam),
              _monthlyView(isMalayalam),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: kSurface, body: body);
  }

  // ---- Daily ----
  Widget _dailyView(bool isMalayalam) {
    final today = _daily.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _heroCard(
          isMalayalam ? 'ഇന്നത്തെ മാർക്ക്' : "Today's Marks",
          '${today['marks']}',
          '${today['done']}/${today['total']} ${isMalayalam ? 'പൂർത്തിയായി' : 'activities'}',
          today['pct'] / 100.0,
        ),
        const SizedBox(height: 16),
        SectionLabel(
          isMalayalam ? 'കഴിഞ്ഞ ദിവസങ്ങൾ' : 'Recent Days',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 12),
        if (_daily.length <= 1)
          EmptyState(
            icon: Icons.history_rounded,
            title: isMalayalam ? 'ഇതുവരെ റെക്കോർഡ് ഇല്ല' : 'No history yet',
            message: isMalayalam
                ? 'ദിനംപ്രതി മാർക്ക് ചെയ്താൽ ഇവിടെ കാണാം'
                : 'Mark your day to see progress here.',
          )
        else
          ..._daily.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _dayRow(d, isMalayalam),
            ),
          ),
      ],
    );
  }

  Widget _dayRow(Map<String, dynamic> d, bool isMalayalam) {
    final pct = d['pct'] as int;
    return SoftCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          _trendIcon(d['trend']),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? d['dateML'] : d['date'],
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 8,
                    backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation(_pctColor(pct)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${d['marks']}',
                style: AppTextStyles.statNumber.copyWith(color: kGreen),
              ),
              Text('$pct%', style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Weekly ----
  Widget _weeklyView(bool isMalayalam) {
    final w = _weekly;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _heroCard(
          isMalayalam ? 'ഈ ആഴ്ച' : 'This Week',
          '${w['totalMarks']}',
          '${w['done']}/${w['total']} ${isMalayalam ? 'പ്രവർത്തനങ്ങൾ' : 'activities'}',
          w['pct'] / 100.0,
        ),
        const SizedBox(height: 16),
        SectionLabel(
          isMalayalam ? 'വിശദാംശങ്ങൾ' : 'Breakdown',
          icon: Icons.bar_chart_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.trending_up_rounded,
                value: '${w['avg']}',
                label: isMalayalam ? 'ശരാശരി' : 'Avg / day',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.emoji_events_rounded,
                value: '${w['best']}',
                label: isMalayalam ? 'മികച്ച ദിനം' : 'Best day',
                tint: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.percent_rounded,
                value: '${w['pct']}%',
                label: isMalayalam ? 'പൂർത്തീകരണം' : 'Completion',
                tint: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.check_circle_rounded,
                value: '${w['done']}',
                label: isMalayalam ? 'പൂർത്തിയായവ' : 'Completed',
                tint: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Monthly ----
  Widget _monthlyView(bool isMalayalam) {
    final m = _monthly;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _heroCard(
          isMalayalam ? 'ഈ മാസം' : 'This Month',
          '${m['totalMarks']}',
          '${m['days']} ${isMalayalam ? 'സജീവ ദിനങ്ങൾ' : 'active days'}',
          m['pct'] / 100.0,
        ),
        const SizedBox(height: 12),
        SoftCard(
          color: kGreenSoft,
          borderColor: kGreen.withValues(alpha: 0.25),
          child: Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: kGreen, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isMalayalam
                      ? 'കഴിഞ്ഞ മാസത്തേക്കാൾ ${m['improve']}% മെച്ചപ്പെട്ടു'
                      : '${m['improve']}% better than last month',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionLabel(
          isMalayalam ? 'വിശദാംശങ്ങൾ' : 'Breakdown',
          icon: Icons.bar_chart_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.trending_up_rounded,
                value: '${m['avg']}',
                label: isMalayalam ? 'ശരാശരി' : 'Avg / day',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.emoji_events_rounded,
                value: '${m['best']}',
                label: isMalayalam ? 'മികച്ച ദിനം' : 'Best day',
                tint: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.percent_rounded,
                value: '${m['pct']}%',
                label: isMalayalam ? 'പൂർത്തീകരണം' : 'Completion',
                tint: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.calendar_month_rounded,
                value: '${m['days']}',
                label: isMalayalam ? 'സജീവ ദിനങ്ങൾ' : 'Active days',
                tint: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Shared ----
  Widget _heroCard(String label, String value, String sub, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF115E59), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D5A34),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendIcon(String trend) {
    late IconData icon;
    late Color color;
    switch (trend) {
      case 'up':
        icon = Icons.trending_up_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'down':
        icon = Icons.trending_down_rounded;
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.trending_flat_rounded;
        color = const Color(0xFFF59E0B);
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Color _pctColor(int pct) {
    if (pct >= 80) return const Color(0xFF10B981); // strong — green
    if (pct >= 50) return const Color(0xFFE0A82E); // fair — amber
    return const Color(0xFFEF4444); // low — red
  }
}
