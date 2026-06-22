import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import 'parent_data.dart';

/// Parent home — overview of all linked children with quick stats.
///
/// Tapping a child opens the per-child detail (progress / ranking /
/// achievements). The "Review" action jumps to pending approvals.
class ParentHomeScreen extends StatelessWidget {
  final bool isMalayalam;
  final String parentName;
  final List<ParentChild> children;
  final List<PortalNotification> notifications;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<ParentChild> onOpenChild;
  final VoidCallback onOpenApprovals;

  const ParentHomeScreen({
    super.key,
    required this.isMalayalam,
    required this.parentName,
    required this.children,
    required this.notifications,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpenChild,
    required this.onOpenApprovals,
  });

  @override
  Widget build(BuildContext context) {
    final totalPending = children.fold<int>(
      0,
      (sum, c) => sum + c.pendingApprovals,
    );
    final todayMarks = children.fold<int>(0, (s, c) => s + c.todayMarks);
    final ranked = children.where((c) => c.rank > 0).toList();
    final bestRank = ranked.isEmpty
        ? 0
        : ranked.map((c) => c.rank).reduce((a, b) => a < b ? a : b);
    final singleChild = children.length == 1;

    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'നമസ്കാരം' : 'Welcome',
            subtitle: parentName,
            icon: Icons.family_restroom_rounded,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PortalNotificationBellAsync(
                  source: PortalNotificationSource.parent,
                  fallback: const [],
                  isMalayalam: isMalayalam,
                ),
                const SizedBox(width: 10),
                PortalProfileAvatar(fallbackName: parentName),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? EmptyState(
                    icon: Icons.family_restroom_rounded,
                    title: isMalayalam ? 'ലോഡ് ചെയ്യുന്നു' : 'Loading',
                    message: isMalayalam
                        ? 'കുട്ടികളുടെ വിവരങ്ങൾ ലോഡ് ചെയ്യുന്നു...'
                        : 'Fetching your children\'s progress...',
                    loading: true,
                  )
                : error != null
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: isMalayalam
                        ? 'ലോഡ് ചെയ്യാനായില്ല'
                        : 'Could not load',
                    message: isMalayalam
                        ? 'വീണ്ടും ശ്രമിക്കാൻ താഴേക്ക് വലിക്കുക'
                        : 'Pull down to retry.',
                  )
                : RefreshIndicator(
                    onRefresh: onRefresh,
                    color: kGreen,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatTile(
                                icon: Icons.star_rounded,
                                value: '$todayMarks',
                                label: isMalayalam
                                    ? 'ഇന്നത്തെ മാർക്ക്'
                                    : "Today's marks",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                icon: Icons.emoji_events_rounded,
                                value: bestRank > 0 ? '#$bestRank' : '—',
                                label: singleChild
                                    ? (isMalayalam
                                          ? 'ക്ലാസ് റാങ്ക്'
                                          : 'Class rank')
                                    : (isMalayalam
                                          ? 'മികച്ച റാങ്ക്'
                                          : 'Best rank'),
                                tint: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                icon: Icons.fact_check_rounded,
                                value: '$totalPending',
                                label: isMalayalam ? 'അംഗീകാരം' : 'To approve',
                                tint: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        if (totalPending > 0) ...[
                          const SizedBox(height: 14),
                          _approvalBanner(totalPending),
                        ],
                        const SizedBox(height: 18),
                        SectionLabel(
                          isMalayalam ? 'എന്റെ കുട്ടികൾ' : 'My Children',
                          icon: Icons.child_care_rounded,
                        ),
                        const SizedBox(height: 12),
                        if (children.isEmpty)
                          EmptyState(
                            icon: Icons.child_care_rounded,
                            title: isMalayalam
                                ? 'കുട്ടികളെ ലിങ്ക് ചെയ്തിട്ടില്ല'
                                : 'No children linked',
                            message: isMalayalam
                                ? 'അഡ്മിനെ ബന്ധപ്പെട്ട് കുട്ടികളെ ലിങ്ക് ചെയ്യുക'
                                : 'Contact the school admin to link your children.',
                          )
                        else
                          ...children.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _childCard(c),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _approvalBanner(int count) {
    return SoftCard(
      color: const Color(0xFFFEF6E7),
      borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
      onTap: onOpenApprovals,
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: Color(0xFFB7791F),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMalayalam
                  ? '$count ദിന റെക്കോർഡുകൾ അംഗീകാരത്തിനായി കാത്തിരിക്കുന്നു'
                  : '$count daily records waiting for your approval',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92600A),
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB7791F)),
        ],
      ),
    );
  }

  Widget _childCard(ParentChild c) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      onTap: () => onOpenChild(c),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  c.avatar,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam ? c.nameMl : c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kHeading,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${isMalayalam ? c.batchNameMl : c.batchName} · ${isMalayalam ? c.lastUpdateMl : c.lastUpdate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _rankPill(c.rank),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  isMalayalam ? 'ഇന്ന്' : 'Today',
                  '${c.todayMarks}',
                  isMalayalam ? 'മാർക്ക്' : 'marks',
                ),
              ),
              _divider(),
              Expanded(
                child: _miniStat(
                  isMalayalam ? 'ആഴ്ച' : 'Week',
                  '${c.weekPct}%',
                  isMalayalam ? 'പൂർത്തി' : 'done',
                ),
              ),
              _divider(),
              Expanded(
                child: _miniStat(
                  isMalayalam ? 'ബാഡ്ജുകൾ' : 'Badges',
                  '${c.badges}',
                  isMalayalam ? 'നേടി' : 'earned',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: c.todayPct / 100.0,
              minHeight: 8,
              backgroundColor: kBorder,
              valueColor: AlwaysStoppedAnimation(
                c.todayPct >= 85
                    ? const Color(0xFF10B981)
                    : c.todayPct >= 60
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isMalayalam
                  ? 'ഇന്നത്തെ പുരോഗതി ${c.todayPct}%'
                  : "Today's progress ${c.todayPct}%",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankPill(int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 15,
            color: Color(0xFFB7791F),
          ),
          const SizedBox(width: 4),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF92600A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: kGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: kHeading,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: kMuted,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: kBorder,
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}
