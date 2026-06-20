import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../components/portal_ui.dart';

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
  bool _initialsOnly = false; // privacy: show initials instead of full names

  final List<Map<String, dynamic>> _daily = [
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

  final List<Map<String, dynamic>> _weekly = [
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

  final List<Map<String, dynamic>> _monthly = [
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

  final List<Map<String, dynamic>> _allTime = [
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

  String _displayName(Map<String, dynamic> s) {
    final name = s['name'] as String;
    if (!_initialsOnly || s['me'] == true) return name;
    final parts = name.trim().split(' ');
    final initials = parts
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join('. ');
    return '$initials.';
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final list = _list;
    final top3 = list.take(3).toList();
    final rest = list.skip(3).toList();

    final segItems = isMalayalam
        ? const ['ദിനം', 'ആഴ്ച', 'മാസം', 'എല്ലാം']
        : const ['Daily', 'Weekly', 'Monthly', 'All-time'];

    final content = list.isEmpty
        ? EmptyState(
            icon: Icons.leaderboard_rounded,
            title: isMalayalam ? 'റാങ്കിംഗ് ഇല്ല' : 'No rankings yet',
            message: isMalayalam
                ? 'മാർക്കിംഗ് തുടങ്ങിയാൽ റാങ്ക് ഇവിടെ കാണാം'
                : 'Rankings appear once marking starts.',
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              _podium(top3, isMalayalam),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SectionLabel(
                      isMalayalam ? 'എല്ലാ റാങ്കുകൾ' : 'All Rankings',
                      icon: Icons.format_list_numbered_rounded,
                    ),
                  ),
                  _privacyToggle(isMalayalam),
                ],
              ),
              const SizedBox(height: 12),
              ...rest.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
          PortalHeader(
            title: isMalayalam ? 'റാങ്കിംഗ്' : 'Leaderboard',
            subtitle: widget.batchName,
            icon: Icons.leaderboard_rounded,
            bottom: PortalSegmented(
              onHeader: true,
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

  // ---- Podium ----
  Widget _podium(List<Map<String, dynamic>> top3, bool isMalayalam) {
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _podiumCol(top3[1], 2, isMalayalam)), // 2nd
        const SizedBox(width: 10),
        Expanded(child: _podiumCol(top3[0], 1, isMalayalam)), // 1st
        const SizedBox(width: 10),
        Expanded(child: _podiumCol(top3[2], 3, isMalayalam)), // 3rd
      ],
    );
  }

  Widget _podiumCol(Map<String, dynamic> s, int place, bool isMalayalam) {
    final cfg = {
      1: {'medal': '🥇', 'color': kGreen, 'h': 92.0},
      2: {'medal': '🥈', 'color': const Color(0xFF94A3B8), 'h': 74.0},
      3: {'medal': '🥉', 'color': const Color(0xFFCD7F32), 'h': 58.0},
    }[place]!;
    final color = cfg['color'] as Color;
    final me = s['me'] == true;

    return Column(
      children: [
        Text(cfg['medal'] as String, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
          child: CircleAvatar(
            radius: place == 1 ? 26 : 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              s['avatar'],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: place == 1 ? 20 : 17,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _initialsOnly && s['me'] != true
              ? _displayName(s)
              : _firstName(s['name']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: me ? kGreen : kHeading,
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
              colors: [color.withValues(alpha: 0.9), color],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Column(
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
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
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
    return SoftCard(
      padding: const EdgeInsets.all(14),
      color: me ? kGreenSoft : Colors.white,
      borderColor: me ? kGreen.withValues(alpha: 0.4) : kBorder,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${s['rank']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: me ? kGreen : kMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 23,
            backgroundColor: (me ? kGreen : kMuted).withValues(alpha: 0.15),
            child: Text(
              s['avatar'],
              style: TextStyle(
                color: me ? kGreen : kBody,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 13),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: me ? kGreen : kHeading,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${s['activities']} ${isMalayalam ? 'പ്രവർത്തനങ്ങൾ' : 'activities'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _trendArrow(s['trend'] as String? ?? 'flat'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: me ? kGreen : kGreenSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${s['marks']}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: me ? Colors.white : kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendArrow(String trend) {
    late IconData icon;
    late Color color;
    switch (trend) {
      case 'up':
        icon = Icons.arrow_upward_rounded;
        color = const Color(0xFF059669);
        break;
      case 'down':
        icon = Icons.arrow_downward_rounded;
        color = const Color(0xFFDC2626);
        break;
      default:
        icon = Icons.remove_rounded;
        color = const Color(0xFF9CA3AF);
    }
    return Icon(icon, size: 18, color: color);
  }

  Widget _privacyToggle(bool isMalayalam) {
    return GestureDetector(
      onTap: () => setState(() => _initialsOnly = !_initialsOnly),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _initialsOnly ? kGreen : kGreenSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _initialsOnly
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 16,
              color: _initialsOnly ? Colors.white : kGreen,
            ),
            const SizedBox(width: 6),
            Text(
              isMalayalam ? 'സ്വകാര്യത' : 'Privacy',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _initialsOnly ? Colors.white : kGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String name) => name.split(' ').first;
}
