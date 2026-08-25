import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../components/portal_ui.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../shared/theme/theme.dart';

/// Leaderboard / ranking screen for a batch.
class LeaderboardScreen extends StatefulWidget {
  final String batchId;
  final String batchName;

  /// When true, renders without its own Scaffold / green header so it can be
  /// embedded inside another shell (e.g. the parent child detail).
  final bool embedded;

  const LeaderboardScreen({
    super.key,
    required this.batchId,
    required this.batchName,
    this.embedded = false,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _tab = 0; // 0=Daily, 1=Weekly, 2=Monthly, 3=All-time
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final res = await MobileApiService.getMyLeaderboard();
    if (!mounted) return;
    List<Map<String, dynamic>> conv(dynamic raw) => (raw as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    setState(() {
      if (res.success && res.data != null) {
        final d = res.data!;
        _daily = conv(d['daily']);
        _weekly = conv(d['weekly']);
        _monthly = conv(d['monthly']);
        _allTime = conv(d['all_time']);
      } else {
        _daily = [];
        _weekly = [];
        _monthly = [];
        _allTime = [];
      }
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _daily = [
    {
      'rank': 1,
      'name': 'Ahmed Ali',
      'marks': 38,
      'activities': 9,
      'avatar': 'A',
      'me': false,
      'trend': 'up',
    },
    {
      'rank': 2,
      'name': 'Fatima Khan',
      'marks': 35,
      'activities': 8,
      'avatar': 'F',
      'me': false,
      'trend': 'down',
    },
    {
      'rank': 3,
      'name': 'Mohammad Hassan',
      'marks': 32,
      'activities': 9,
      'avatar': 'M',
      'me': true,
      'trend': 'up',
    },
    {
      'rank': 4,
      'name': 'Aisha Ibrahim',
      'marks': 28,
      'activities': 7,
      'avatar': 'A',
      'me': false,
      'trend': 'flat',
    },
    {
      'rank': 5,
      'name': 'Khalid Abdullah',
      'marks': 25,
      'activities': 6,
      'avatar': 'K',
      'me': false,
      'trend': 'down',
    },
    {
      'rank': 6,
      'name': 'Zainab Ahmed',
      'marks': 22,
      'activities': 5,
      'avatar': 'Z',
      'me': false,
      'trend': 'up',
    },
  ];

  List<Map<String, dynamic>> _weekly = [
    {
      'rank': 1,
      'name': 'Fatima Khan',
      'marks': 245,
      'activities': 56,
      'avatar': 'F',
      'me': false,
      'trend': 'up',
    },
    {
      'rank': 2,
      'name': 'Ahmed Ali',
      'marks': 228,
      'activities': 53,
      'avatar': 'A',
      'me': false,
      'trend': 'down',
    },
    {
      'rank': 3,
      'name': 'Mohammad Hassan',
      'marks': 215,
      'activities': 50,
      'avatar': 'M',
      'me': true,
      'trend': 'up',
    },
    {
      'rank': 4,
      'name': 'Aisha Ibrahim',
      'marks': 192,
      'activities': 45,
      'avatar': 'A',
      'me': false,
      'trend': 'flat',
    },
    {
      'rank': 5,
      'name': 'Khalid Abdullah',
      'marks': 168,
      'activities': 40,
      'avatar': 'K',
      'me': false,
      'trend': 'down',
    },
  ];

  List<Map<String, dynamic>> _monthly = [
    {
      'rank': 1,
      'name': 'Ahmed Ali',
      'marks': 920,
      'activities': 228,
      'avatar': 'A',
      'me': false,
      'trend': 'up',
    },
    {
      'rank': 2,
      'name': 'Mohammad Hassan',
      'marks': 880,
      'activities': 220,
      'avatar': 'M',
      'me': true,
      'trend': 'up',
    },
    {
      'rank': 3,
      'name': 'Fatima Khan',
      'marks': 845,
      'activities': 210,
      'avatar': 'F',
      'me': false,
      'trend': 'down',
    },
    {
      'rank': 4,
      'name': 'Khalid Abdullah',
      'marks': 760,
      'activities': 190,
      'avatar': 'K',
      'me': false,
      'trend': 'flat',
    },
    {
      'rank': 5,
      'name': 'Aisha Ibrahim',
      'marks': 712,
      'activities': 178,
      'avatar': 'A',
      'me': false,
      'trend': 'down',
    },
  ];

  List<Map<String, dynamic>> _allTime = [
    {
      'rank': 1,
      'name': 'Fatima Khan',
      'marks': 6840,
      'activities': 1620,
      'avatar': 'F',
      'me': false,
      'trend': 'flat',
    },
    {
      'rank': 2,
      'name': 'Ahmed Ali',
      'marks': 6510,
      'activities': 1555,
      'avatar': 'A',
      'me': false,
      'trend': 'up',
    },
    {
      'rank': 3,
      'name': 'Mohammad Hassan',
      'marks': 6230,
      'activities': 1490,
      'avatar': 'M',
      'me': true,
      'trend': 'up',
    },
    {
      'rank': 4,
      'name': 'Khalid Abdullah',
      'marks': 5870,
      'activities': 1402,
      'avatar': 'K',
      'me': false,
      'trend': 'down',
    },
    {
      'rank': 5,
      'name': 'Aisha Ibrahim',
      'marks': 5510,
      'activities': 1320,
      'avatar': 'A',
      'me': false,
      'trend': 'flat',
    },
  ];

  List<Map<String, dynamic>> get _list {
    switch (_tab) {
      case 1:
        return _weekly;
      case 2:
        return _monthly;
      case 3:
        return _allTime;
      default:
        return _daily;
    }
  }

  String _displayName(Map<String, dynamic> s) => s['name'] as String;

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final list = _list;
    final top3 = list.take(3).toList();
    final rest = list.skip(3).toList();

    final segItems = isMalayalam
        ? const ['ദിനം', 'ആഴ്ച', 'മാസം', 'എല്ലാം']
        : const ['Daily', 'Weekly', 'Monthly', 'All-time'];

    final content = _loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: CircularProgressIndicator(),
            ),
          )
        : list.isEmpty
        ? EmptyState(
            icon: Icons.leaderboard_rounded,
            title: isMalayalam ? 'റാങ്കിംഗ് ഇല്ല' : 'No rankings yet',
            message: isMalayalam
                ? 'മാർക്കിംഗ് തുടങ്ങിയാൽ റാങ്ക് ഇവിടെ കാണാം'
                : 'Rankings appear once marking starts.',
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _podium(top3, isMalayalam),
              const SizedBox(height: 14),
              SectionLabel(
                isMalayalam ? 'എല്ലാ റാങ്കുകൾ' : 'All Rankings',
                icon: Icons.format_list_numbered_rounded,
              ),
              const SizedBox(height: 10),
              ...rest.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _row(s, isMalayalam),
                ),
              ),
            ],
          );

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
          MinimalHeader(
            title: isMalayalam ? 'റാങ്കിംഗ്' : 'Leaderboard',
            subtitle: widget.batchName,
            isMalayalam: isMalayalam,
            notifications: const [],
            notificationSource: PortalNotificationSource.student,
            avatarName:
                MobileGoogleAuthService.currentUser?.name ?? widget.batchName,
            bottom: PortalSegmented(
              index: _tab,
              items: segItems,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
        Expanded(child: content),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: kSurface, body: body);
  }

  // ---- Podium hero ----
  Widget _podium(List<Map<String, dynamic>> top3, bool isMalayalam) {
    if (top3.isEmpty) return const SizedBox.shrink();
    if (top3.length < 3) {
      return Column(
        children: top3
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _row(s, isMalayalam),
              ),
            )
            .toList(),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF115E59), Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: kGreen.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Text(
                isMalayalam ? 'മികച്ച പ്രകടനക്കാർ' : 'Top Performers',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _podiumCol(top3[1], 2, isMalayalam)), // 2nd
              const SizedBox(width: 8),
              Expanded(child: _podiumCol(top3[0], 1, isMalayalam)), // 1st
              const SizedBox(width: 8),
              Expanded(child: _podiumCol(top3[2], 3, isMalayalam)), // 3rd
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumCol(Map<String, dynamic> s, int place, bool isMalayalam) {
    final cfg = {
      1: {'color': const Color(0xFFFFD54A), 'h': 102.0},
      2: {'color': const Color(0xFFE2E8F0), 'h': 82.0},
      3: {'color': const Color(0xFFF0B27A), 'h': 68.0},
    }[place]!;
    final color = cfg['color'] as Color;
    final me = s['me'] == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: place == 1
              ? const Text('👑', style: TextStyle(fontSize: 22))
              : null,
        ),
        const SizedBox(height: 2),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: place == 1 ? 28 : 23,
                backgroundColor: Colors.white,
                child: Text(
                  s['avatar'],
                  style: TextStyle(
                    color: const Color(0xFF115E59),
                    fontWeight: FontWeight.w800,
                    fontSize: place == 1 ? 22 : 18,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [color, _darken(color)]),
                  border: Border.all(color: const Color(0xFF0F766E), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$place',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF115E59),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _firstName(s['name']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (me)
          Text(
            isMalayalam ? '(ഞാൻ)' : '(You)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: cfg['h'] as double,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.30),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${s['marks']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                isMalayalam ? 'പോയിന്റ്' : 'pts',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- List row ----
  Widget _row(Map<String, dynamic> s, bool isMalayalam) {
    final me = s['me'] == true;
    final rank = s['rank'] as int;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: me ? kGreenSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: me ? kGreen.withValues(alpha: 0.45) : kBorder,
          width: me ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (me ? kGreen : Colors.black).withValues(
              alpha: me ? 0.10 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: me
                    ? [kGreen, _darken(kGreen)]
                    : [const Color(0xFFEEF2F4), const Color(0xFFE2E8EC)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: me ? Colors.white : kMuted,
              ),
            ),
          ),
          const SizedBox(width: 11),
          CircleAvatar(
            radius: 21,
            backgroundColor: (me ? kGreen : kMuted).withValues(alpha: 0.14),
            child: Text(
              s['avatar'],
              style: TextStyle(
                color: me ? kGreen : kBody,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me
                      ? '${_displayName(s)} ${isMalayalam ? '(ഞാൻ)' : '(You)'}'
                      : _displayName(s),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: me ? kGreen : AppColors.heading,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 13, color: kMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${s['activities']} ${isMalayalam ? 'പ്രവർത്തനങ്ങൾ' : 'activities'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _trendChip(s['trend'] as String? ?? 'flat'),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s['marks']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: me ? kGreen : kHeading,
                ),
              ),
              Text(
                isMalayalam ? 'പോയിന്റ്' : 'pts',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendChip(String trend) {
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
        color = const Color(0xFF94A3B8);
    }
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Color _darken(Color c, [double amount = 0.14]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  String _firstName(String name) => name.split(' ').first;
}
