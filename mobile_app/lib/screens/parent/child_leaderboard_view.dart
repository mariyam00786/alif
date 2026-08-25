import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../services/parent_api_service.dart';

/// Live batch leaderboard for a single child (parent view).
///
/// The child's own row is highlighted. Fed by the backend
/// `/me/children/:id/leaderboard` endpoint.
class ChildLeaderboardView extends StatefulWidget {
  final String childId;
  final bool isMalayalam;

  const ChildLeaderboardView({
    super.key,
    required this.childId,
    required this.isMalayalam,
  });

  @override
  State<ChildLeaderboardView> createState() => _ChildLeaderboardViewState();
}

class _ChildLeaderboardViewState extends State<ChildLeaderboardView> {
  static const _periods = ['daily', 'weekly'];
  int _periodIndex = 1; // default: weekly
  late Future<List<LeaderEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentApiService.fetchLeaderboard(
      widget.childId,
      _periods[_periodIndex],
    );
  }

  void _selectPeriod(int i) {
    if (i == _periodIndex) return;
    setState(() {
      _periodIndex = i;
      _future = ParentApiService.fetchLeaderboard(
        widget.childId,
        _periods[i],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: PortalSegmented(
            index: _periodIndex,
            items: isMalayalam
                ? const ['ദിവസം', 'ആഴ്ച']
                : const ['Daily', 'Weekly'],
            onChanged: _selectPeriod,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<LeaderEntry>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return EmptyState(
                  icon: Icons.leaderboard_rounded,
                  title: isMalayalam ? 'ലോഡ് ചെയ്യുന്നു' : 'Loading',
                  message: isMalayalam
                      ? 'റാങ്കിങ് ലോഡ് ചെയ്യുന്നു...'
                      : 'Fetching ranking...',
                  loading: true,
                );
              }
              if (snap.hasError || !snap.hasData) {
                return EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: isMalayalam ? 'ലോഡ് ചെയ്യാനായില്ല' : 'Could not load',
                  message: isMalayalam
                      ? 'വീണ്ടും ശ്രമിക്കുക'
                      : 'Please try again later.',
                );
              }
              final entries = snap.data!;
              if (entries.isEmpty) {
                return EmptyState(
                  icon: Icons.leaderboard_rounded,
                  title: isMalayalam ? 'വിവരം ഇല്ല' : 'No ranking yet',
                  message: isMalayalam
                      ? 'ഈ കാലയളവിൽ പ്രവർത്തനങ്ങൾ ഇല്ല'
                      : 'No activity in this period.',
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  for (final e in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _row(e, isMalayalam),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(LeaderEntry e, bool isMalayalam) {
    final isTop3 = e.rank <= 3;
    final rankColor = switch (e.rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF94A3B8),
      3 => const Color(0xFFB87333),
      _ => kMuted,
    };
    final name = isMalayalam ? e.nameMl : e.name;

    return SoftCard(
      color: e.isSelf ? kGreenSoft : null,
      borderColor: e.isSelf ? kGreen.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: isTop3
                ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 24)
                : Text(
                    '${e.rank}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (e.isSelf ? kGreen : const Color(0xFF64748B)).withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: e.isSelf ? kGreen : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: e.isSelf ? FontWeight.w800 : FontWeight.w700,
                color: kHeading,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${e.marks}',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: kGreen,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isMalayalam ? 'മാർക്ക്' : 'pts',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
