import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../services/parent_api_service.dart';
import 'parent_data.dart';

/// Achievements / badges grid for a single child (parent view).
class ChildAchievementsView extends StatefulWidget {
  final String childId;
  final bool isMalayalam;

  const ChildAchievementsView({
    super.key,
    required this.childId,
    required this.isMalayalam,
  });

  @override
  State<ChildAchievementsView> createState() => _ChildAchievementsViewState();
}

class _ChildAchievementsViewState extends State<ChildAchievementsView> {
  late Future<ChildBadgeData> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentApiService.fetchBadges(widget.childId);
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;
    return FutureBuilder<ChildBadgeData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return EmptyState(
            icon: Icons.military_tech_rounded,
            title: isMalayalam ? 'ലോഡ് ചെയ്യുന്നു' : 'Loading',
            message: isMalayalam
                ? 'ബാഡ്ജുകൾ ലോഡ് ചെയ്യുന്നു...'
                : 'Fetching badges...',
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

        final data = snap.data!;
        final badges = data.badges;
        final earned = data.earned;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            SoftCard(
              color: kGreenSoft,
              borderColor: kGreen.withValues(alpha: 0.25),
              child: Row(
                children: [
                  const Icon(
                    Icons.military_tech_rounded,
                    color: kGreen,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$earned / ${data.total} ${isMalayalam ? 'ബാഡ്ജുകൾ' : 'badges'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: kGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMalayalam
                              ? 'നേടിയ നേട്ടങ്ങൾ'
                              : 'Achievements unlocked',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionLabel(
              isMalayalam ? 'ബാഡ്ജുകൾ' : 'Badges',
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: 12),
            if (badges.isEmpty)
              EmptyState(
                icon: Icons.workspace_premium_rounded,
                title: isMalayalam ? 'ബാഡ്ജുകൾ ഇല്ല' : 'No badges yet',
                message: isMalayalam
                    ? 'പ്രവർത്തനങ്ങൾ പൂർത്തിയാക്കി ബാഡ്ജുകൾ നേടാം'
                    : 'Complete activities to earn badges.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: badges.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.86,
                    ),
                itemBuilder: (context, i) => _badgeCard(badges[i]),
              ),
          ],
        );
      },
    );
  }

  Widget _badgeCard(ChildBadge b) {
    final isMalayalam = widget.isMalayalam;
    final tint = b.earned ? b.color : const Color(0xFF94A3B8);
    return Opacity(
      opacity: b.earned ? 1 : 0.6,
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(b.icon, size: 26, color: tint),
                ),
                if (!b.earned)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isMalayalam ? b.titleMl : b.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kHeading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isMalayalam ? b.detailMl : b.detail,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: kMuted,
                height: 1.3,
              ),
            ),
            const Spacer(),
            if (b.earned)
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Earned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              )
            else
              Text(
                isMalayalam ? 'പുരോഗതിയിൽ' : 'In progress',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
