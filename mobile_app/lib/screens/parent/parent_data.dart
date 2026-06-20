import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';

/// A child linked to the signed-in parent.
class ParentChild {
  final String id;
  final String name;
  final String nameMl;
  final String batchId;
  final String batchName;
  final String batchNameMl;
  final String avatar; // initial letter
  final Color color;
  final int todayMarks;
  final int todayPct;
  final int weekPct;
  final int monthPct;
  final int rank;
  final int batchSize;
  final int pendingApprovals;
  final int badges;
  final bool active;
  final String lastUpdate;
  final String lastUpdateMl;

  const ParentChild({
    required this.id,
    required this.name,
    required this.nameMl,
    required this.batchId,
    required this.batchName,
    required this.batchNameMl,
    required this.avatar,
    required this.color,
    required this.todayMarks,
    required this.todayPct,
    required this.weekPct,
    required this.monthPct,
    required this.rank,
    required this.batchSize,
    required this.pendingApprovals,
    required this.badges,
    required this.active,
    required this.lastUpdate,
    required this.lastUpdateMl,
  });
}

/// An earned or in-progress achievement / badge for a child.
class ChildBadge {
  final String title;
  final String titleMl;
  final IconData icon;
  final Color color;
  final bool earned;
  final String detail;
  final String detailMl;

  const ChildBadge({
    required this.title,
    required this.titleMl,
    required this.icon,
    required this.color,
    required this.earned,
    required this.detail,
    required this.detailMl,
  });
}

/// A daily record awaiting parent approval.
class PendingApproval {
  final String id;
  final String childId;
  final String dateLabel;
  final String dateLabelMl;
  final int marks;
  final int completed;
  final int total;
  final List<String> highlights;
  final List<String> highlightsMl;

  // Live-data fields (populated from the API; null for static mock).
  final String? rawDate;
  final String? childName;
  final String? childNameMl;
  final String? childAvatar;
  final Color? childColor;

  const PendingApproval({
    required this.id,
    required this.childId,
    required this.dateLabel,
    required this.dateLabelMl,
    required this.marks,
    required this.completed,
    required this.total,
    required this.highlights,
    required this.highlightsMl,
    this.rawDate,
    this.childName,
    this.childNameMl,
    this.childAvatar,
    this.childColor,
  });
}

/// Central mock data source for the parent portal.
///
/// Mirrors the inline-mock pattern used by the student screens. When the
/// backend parent endpoints are wired, replace these getters with API calls.
class ParentData {
  ParentData._();

  static const List<ParentChild> children = [
    ParentChild(
      id: 'student-001',
      name: 'Ahmed Ali',
      nameMl: 'അഹമ്മദ് അലി',
      batchId: 'batch-001',
      batchName: 'Class A',
      batchNameMl: 'ക്ലാസ് എ',
      avatar: 'A',
      color: kGreen,
      todayMarks: 32,
      todayPct: 95,
      weekPct: 92,
      monthPct: 88,
      rank: 3,
      batchSize: 24,
      pendingApprovals: 1,
      badges: 6,
      active: true,
      lastUpdate: '2 hours ago',
      lastUpdateMl: '2 മണിക്കൂർ മുമ്പ്',
    ),
    ParentChild(
      id: 'student-002',
      name: 'Fatima Khan',
      nameMl: 'ഫാത്തിമ ഖാൻ',
      batchId: 'batch-002',
      batchName: 'Class B',
      batchNameMl: 'ക്ലാസ് ബി',
      avatar: 'F',
      color: Color(0xFFF59E0B),
      todayMarks: 28,
      todayPct: 88,
      weekPct: 84,
      monthPct: 81,
      rank: 1,
      batchSize: 22,
      pendingApprovals: 2,
      badges: 9,
      active: true,
      lastUpdate: '1 hour ago',
      lastUpdateMl: '1 മണിക്കൂർ മുമ്പ്',
    ),
  ];

  static ParentChild childById(String id) =>
      children.firstWhere((c) => c.id == id, orElse: () => children.first);

  static List<ChildBadge> badgesFor(String childId) => const [
    ChildBadge(
      title: '7 Day Streak',
      titleMl: '7 ദിന സ്ട്രീക്ക്',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEF4444),
      earned: true,
      detail: 'Marked every day this week',
      detailMl: 'ഈ ആഴ്ച എല്ലാ ദിവസവും അടയാളപ്പെടുത്തി',
    ),
    ChildBadge(
      title: 'Prayer Master',
      titleMl: 'നമസ്കാര വിജയി',
      icon: Icons.mosque_rounded,
      color: kGreen,
      earned: true,
      detail: 'All 5 prayers for 30 days',
      detailMl: '30 ദിവസം 5 നേരവും നമസ്കാരം',
    ),
    ChildBadge(
      title: 'Quran Reader',
      titleMl: 'ഖുർആൻ പാരായണം',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF3B82F6),
      earned: true,
      detail: '100 pages recited',
      detailMl: '100 പേജ് പാരായണം ചെയ്തു',
    ),
    ChildBadge(
      title: 'Top 3 Rank',
      titleMl: 'ടോപ് 3 റാങ്ക്',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFF59E0B),
      earned: true,
      detail: 'Reached top 3 in batch',
      detailMl: 'ബാച്ചിൽ ടോപ് 3 ൽ എത്തി',
    ),
    ChildBadge(
      title: 'Perfect Day',
      titleMl: 'പെർഫെക്റ്റ് ഡേ',
      icon: Icons.star_rounded,
      color: Color(0xFF10B981),
      earned: true,
      detail: 'Full marks in a day',
      detailMl: 'ഒരു ദിവസം മുഴുവൻ മാർക്ക്',
    ),
    ChildBadge(
      title: 'Early Riser',
      titleMl: 'നേരത്തെ ഉണരുന്നവൻ',
      icon: Icons.wb_twilight_rounded,
      color: Color(0xFF8B5CF6),
      earned: true,
      detail: 'Fajr on time for 14 days',
      detailMl: '14 ദിവസം സുബ്ഹി കൃത്യസമയത്ത്',
    ),
    ChildBadge(
      title: '30 Day Streak',
      titleMl: '30 ദിന സ്ട്രീക്ക്',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF94A3B8),
      earned: false,
      detail: '12 / 30 days completed',
      detailMl: '12 / 30 ദിവസം പൂർത്തിയായി',
    ),
    ChildBadge(
      title: 'Dhikr Champion',
      titleMl: 'ദിക്ർ ചാമ്പ്യൻ',
      icon: Icons.favorite_rounded,
      color: Color(0xFF94A3B8),
      earned: false,
      detail: 'Daily dhikr for 21 days',
      detailMl: '21 ദിവസം ദിക്ർ',
    ),
  ];

  static List<PendingApproval> pendingApprovals() => const [
    PendingApproval(
      id: 'rec-001',
      childId: 'student-001',
      dateLabel: 'Today',
      dateLabelMl: 'ഇന്ന്',
      marks: 32,
      completed: 9,
      total: 9,
      highlights: ['All 5 prayers', 'Quran 4 pages', 'Dhikr & Duas'],
      highlightsMl: ['5 നേരവും നമസ്കാരം', 'ഖുർആൻ 4 പേജ്', 'ദിക്ർ & ദുആ'],
    ),
    PendingApproval(
      id: 'rec-002',
      childId: 'student-002',
      dateLabel: 'Today',
      dateLabelMl: 'ഇന്ന്',
      marks: 28,
      completed: 8,
      total: 9,
      highlights: ['4 prayers', 'Quran 2 pages', 'Morning Adhkar'],
      highlightsMl: ['4 നമസ്കാരം', 'ഖുർആൻ 2 പേജ്', 'പ്രഭാത അദ്കാർ'],
    ),
    PendingApproval(
      id: 'rec-003',
      childId: 'student-002',
      dateLabel: 'Yesterday',
      dateLabelMl: 'ഇന്നലെ',
      marks: 30,
      completed: 8,
      total: 9,
      highlights: ['All 5 prayers', 'Quran 3 pages'],
      highlightsMl: ['5 നേരവും നമസ്കാരം', 'ഖുർആൻ 3 പേജ്'],
    ),
  ];

  static List<PortalNotification> notifications() => const [
    PortalNotification(
      title: 'Monthly report published',
      titleMl: 'മാസ റിപ്പോർട്ട് പ്രസിദ്ധീകരിച്ചു',
      body: 'Ahmed\'s monthly Ihthisab summary is ready to view.',
      bodyMl: 'അഹമ്മദിന്റെ മാസ ഇഹ്തിസാബ് സംഗ്രഹം തയ്യാറാണ്.',
      timeAgo: '2 hours ago',
      timeAgoMl: '2 മണിക്കൂർ മുമ്പ്',
      icon: Icons.assessment_rounded,
      color: kGreen,
      unread: true,
    ),
    PortalNotification(
      title: 'Approval pending',
      titleMl: 'അംഗീകാരം ബാക്കി',
      body: 'Fatima has 2 daily records waiting for your approval.',
      bodyMl: 'ഫാത്തിമയുടെ 2 ദിന റെക്കോർഡുകൾ അംഗീകാരത്തിനായി കാത്തിരിക്കുന്നു.',
      timeAgo: '5 hours ago',
      timeAgoMl: '5 മണിക്കൂർ മുമ്പ്',
      icon: Icons.fact_check_rounded,
      color: Color(0xFFF59E0B),
      unread: true,
    ),
    PortalNotification(
      title: 'New badge earned',
      titleMl: 'പുതിയ ബാഡ്ജ് നേടി',
      body: 'Ahmed earned the "Prayer Master" badge. Congratulations!',
      bodyMl: 'അഹമ്മദ് "നമസ്കാര വിജയി" ബാഡ്ജ് നേടി. അഭിനന്ദനങ്ങൾ!',
      timeAgo: 'Yesterday',
      timeAgoMl: 'ഇന്നലെ',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF8B5CF6),
      unread: false,
    ),
    PortalNotification(
      title: 'Holiday notice',
      titleMl: 'അവധി അറിയിപ്പ്',
      body: 'The school will remain closed this Friday for maintenance.',
      bodyMl: 'അറ്റകുറ്റപ്പണികൾക്കായി ഈ വെള്ളിയാഴ്ച സ്കൂൾ അവധിയായിരിക്കും.',
      timeAgo: '2 days ago',
      timeAgoMl: '2 ദിവസം മുമ്പ്',
      icon: Icons.campaign_rounded,
      color: Color(0xFF3B82F6),
      unread: false,
    ),
  ];
}
