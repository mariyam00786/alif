import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../components/portal_ui.dart';
import '../constants/apis.dart';
import '../screens/parent/parent_data.dart';
import 'api_service.dart';

/// Live API client for the parent portal.
///
/// Talks to the backend `/api/parents/*` endpoints, reusing the auth token
/// stored by [MobileApiService] after sign-in. Responses are mapped onto the
/// UI model classes already used by the parent screens.
class ParentApiService {
  static const String _base = Apis.baseUrl;
  static const Duration _timeout = Duration(seconds: 20);

  static Map<String, String> _headers() {
    final token = MobileApiService.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static const List<Color> _palette = [
    Color(0xFF2D5A34),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEF4444),
  ];

  static Color _colorFor(String id) {
    final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  static String _initial(String name) =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  static List<dynamic> _list(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError(body['message']?.toString() ?? 'Request failed');
    }
    return (body['data'] as List?) ?? const [];
  }

  static Map<String, dynamic> _object(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError(body['message']?.toString() ?? 'Request failed');
    }
    return (body['data'] as Map<String, dynamic>?) ?? const {};
  }

  // ===== Children overview =====

  static Future<List<ParentChild>> fetchChildren() async {
    final res = await http
        .get(Uri.parse('$_base/parents/me/children'), headers: _headers())
        .timeout(_timeout);
    return _list(res).map((e) => _mapChild(e as Map<String, dynamic>)).toList();
  }

  static ParentChild _mapChild(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? '';
    final name = j['name']?.toString() ?? 'Student';
    return ParentChild(
      id: id,
      name: name,
      nameMl: (j['name_ml']?.toString().isNotEmpty ?? false)
          ? j['name_ml'].toString()
          : name,
      batchId: j['batch_id']?.toString() ?? '',
      batchName: j['batch_name']?.toString() ?? '—',
      batchNameMl:
          j['batch_name_ml']?.toString() ??
          (j['batch_name']?.toString() ?? '—'),
      avatar: _initial(name),
      color: _colorFor(id),
      todayMarks: (j['today_marks'] as num?)?.toInt() ?? 0,
      todayPct: (j['today_pct'] as num?)?.toInt() ?? 0,
      weekPct: (j['week_pct'] as num?)?.toInt() ?? 0,
      monthPct: (j['month_pct'] as num?)?.toInt() ?? 0,
      rank: (j['rank'] as num?)?.toInt() ?? 0,
      batchSize: (j['batch_size'] as num?)?.toInt() ?? 0,
      pendingApprovals: (j['pending_approvals'] as num?)?.toInt() ?? 0,
      badges: (j['badges'] as num?)?.toInt() ?? 0,
      active: j['active'] == true,
      lastUpdate: ((j['today_marks'] as num?)?.toInt() ?? 0) > 0
          ? 'Updated today'
          : 'No update today',
      lastUpdateMl: ((j['today_marks'] as num?)?.toInt() ?? 0) > 0
          ? 'ഇന്ന് അപ്ഡേറ്റ് ചെയ്തു'
          : 'ഇന്ന് അപ്ഡേറ്റ് ഇല്ല',
    );
  }

  // ===== Approvals =====

  static Future<List<PendingApproval>> fetchApprovals() async {
    final res = await http
        .get(Uri.parse('$_base/parents/me/approvals'), headers: _headers())
        .timeout(_timeout);
    return _list(
      res,
    ).map((e) => _mapApproval(e as Map<String, dynamic>)).toList();
  }

  static PendingApproval _mapApproval(Map<String, dynamic> j) {
    final highlights = (j['highlights'] as List?) ?? const [];
    final childName = j['child_name']?.toString() ?? 'Student';
    final childNameMl = (j['child_name_ml']?.toString().isNotEmpty ?? false)
        ? j['child_name_ml'].toString()
        : childName;
    final childId = j['child_id']?.toString() ?? '';
    final rawDate = j['date']?.toString() ?? '';
    return PendingApproval(
      id: j['id']?.toString() ?? '${childId}_$rawDate',
      childId: childId,
      dateLabel: _dateLabel(rawDate, false),
      dateLabelMl: _dateLabel(rawDate, true),
      marks: (j['marks'] as num?)?.toInt() ?? 0,
      completed: (j['completed'] as num?)?.toInt() ?? 0,
      total: (j['total'] as num?)?.toInt() ?? 0,
      highlights: highlights.map((h) => (h['name'] ?? '').toString()).toList(),
      highlightsMl: highlights
          .map((h) => ((h['name_ml'] ?? h['name']) ?? '').toString())
          .toList(),
      rawDate: rawDate,
      childName: childName,
      childNameMl: childNameMl,
      childAvatar: _initial(childName),
      childColor: _colorFor(childId),
    );
  }

  static String _dateLabel(String date, bool ml) {
    if (date.isEmpty) return ml ? 'തീയതി' : 'Date';
    final today = DateTime.now().toUtc();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final yest = today.subtract(const Duration(days: 1));
    final yestStr =
        '${yest.year.toString().padLeft(4, '0')}-${yest.month.toString().padLeft(2, '0')}-${yest.day.toString().padLeft(2, '0')}';
    if (date == todayStr) return ml ? 'ഇന്ന്' : 'Today';
    if (date == yestStr) return ml ? 'ഇന്നലെ' : 'Yesterday';
    return date;
  }

  static Future<int> approve(String childId, String date) async {
    final res = await http
        .post(
          Uri.parse('$_base/parents/me/approvals/$childId/$date/approve'),
          headers: _headers(),
        )
        .timeout(_timeout);
    return (_object(res)['approved'] as num?)?.toInt() ?? 0;
  }

  static Future<void> reject(String childId, String date) async {
    await http
        .post(
          Uri.parse('$_base/parents/me/approvals/$childId/$date/reject'),
          headers: _headers(),
        )
        .timeout(_timeout);
  }

  // ===== Badges =====

  static Future<ChildBadgeData> fetchBadges(String childId) async {
    final res = await http
        .get(
          Uri.parse('$_base/parents/me/children/$childId/badges'),
          headers: _headers(),
        )
        .timeout(_timeout);
    final data = _object(res);
    final list = (data['badges'] as List?) ?? const [];
    return ChildBadgeData(
      earned: (data['earned_count'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? list.length,
      badges: list.map((e) => _mapBadge(e as Map<String, dynamic>)).toList(),
    );
  }

  static ChildBadge _mapBadge(Map<String, dynamic> j) {
    final name = j['name']?.toString() ?? 'Badge';
    final desc = j['description']?.toString() ?? '';
    final earned = j['earned'] == true;
    return ChildBadge(
      title: name,
      titleMl: (j['name_ml']?.toString().isNotEmpty ?? false)
          ? j['name_ml'].toString()
          : name,
      icon: _badgeIcon(name),
      color: _badgeColor(name),
      earned: earned,
      detail: desc,
      detailMl: desc,
    );
  }

  static IconData _badgeIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('prayer') || n.contains('salah')) {
      return Icons.mosque_rounded;
    }
    if (n.contains('quran')) return Icons.menu_book_rounded;
    if (n.contains('streak') || n.contains('day')) {
      return Icons.local_fire_department_rounded;
    }
    if (n.contains('rank') || n.contains('top')) {
      return Icons.emoji_events_rounded;
    }
    if (n.contains('dhikr')) return Icons.favorite_rounded;
    if (n.contains('fajr') || n.contains('early') || n.contains('riser')) {
      return Icons.wb_twilight_rounded;
    }
    if (n.contains('perfect') || n.contains('star')) {
      return Icons.star_rounded;
    }
    return Icons.military_tech_rounded;
  }

  static Color _badgeColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('prayer') || n.contains('salah')) {
      return const Color(0xFF2D5A34);
    }
    if (n.contains('quran')) return const Color(0xFF3B82F6);
    if (n.contains('streak') || n.contains('day')) {
      return const Color(0xFFEF4444);
    }
    if (n.contains('rank') || n.contains('top')) return const Color(0xFFF59E0B);
    if (n.contains('dhikr')) return const Color(0xFFEC4899);
    if (n.contains('early') || n.contains('riser')) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF10B981);
  }

  // ===== Progress =====

  static Future<ChildProgress> fetchProgress(
    String childId,
    String period,
  ) async {
    final res = await http
        .get(
          Uri.parse(
            '$_base/parents/me/children/$childId/progress?period=$period',
          ),
          headers: _headers(),
        )
        .timeout(_timeout);
    final data = _object(res);
    final series = (data['series'] as List?) ?? const [];
    final breakdown = (data['breakdown'] as List?) ?? const [];
    return ChildProgress(
      period: data['period']?.toString() ?? period,
      totalMarks: (data['total_marks'] as num?)?.toInt() ?? 0,
      completionPct: (data['completion_pct'] as num?)?.toInt() ?? 0,
      series: series
          .map(
            (e) => ProgressDay(
              date: e['date']?.toString() ?? '',
              marks: (e['marks'] as num?)?.toInt() ?? 0,
              completed: (e['completed'] as num?)?.toInt() ?? 0,
              total: (e['total'] as num?)?.toInt() ?? 0,
              pct: (e['pct'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(),
      breakdown: breakdown
          .map(
            (e) => ProgressCategory(
              category: e['category']?.toString() ?? 'Other',
              categoryMl: (e['category_ml']?.toString().isNotEmpty ?? false)
                  ? e['category_ml'].toString()
                  : (e['category']?.toString() ?? 'Other'),
              marks: (e['marks'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(),
    );
  }

  // ===== Leaderboard =====

  static Future<List<LeaderEntry>> fetchLeaderboard(
    String childId,
    String period,
  ) async {
    final res = await http
        .get(
          Uri.parse(
            '$_base/parents/me/children/$childId/leaderboard?period=$period',
          ),
          headers: _headers(),
        )
        .timeout(_timeout);
    final data = _object(res);
    final entries = (data['entries'] as List?) ?? const [];
    return entries
        .map(
          (e) => LeaderEntry(
            rank: (e['rank'] as num?)?.toInt() ?? 0,
            name: e['name']?.toString() ?? 'Student',
            nameMl: (e['name_ml']?.toString().isNotEmpty ?? false)
                ? e['name_ml'].toString()
                : (e['name']?.toString() ?? 'Student'),
            marks: (e['marks'] as num?)?.toInt() ?? 0,
            isSelf: e['is_self'] == true,
          ),
        )
        .toList();
  }

  // ===== Notifications =====

  static Future<List<PortalNotification>> fetchNotifications() async {
    final res = await http
        .get(Uri.parse('$_base/parents/me/notifications'), headers: _headers())
        .timeout(_timeout);
    return _list(
      res,
    ).map((e) => _mapNotification(e as Map<String, dynamic>)).toList();
  }

  static PortalNotification _mapNotification(Map<String, dynamic> j) {
    final title = j['title']?.toString() ?? '';
    final body = j['body']?.toString() ?? '';
    return PortalNotification(
      title: title,
      titleMl: title,
      body: body,
      bodyMl: body,
      timeAgo: _timeAgo(j['created_at']?.toString(), false),
      timeAgoMl: _timeAgo(j['created_at']?.toString(), true),
      icon: Icons.campaign_rounded,
      color: const Color(0xFF3B82F6),
      unread: false,
    );
  }

  static String _timeAgo(String? iso, bool ml) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return ml ? '$m മിനിറ്റ് മുമ്പ്' : '${m}m ago';
    }
    if (diff.inHours < 24) {
      return ml ? '${diff.inHours} മണിക്കൂർ മുമ്പ്' : '${diff.inHours}h ago';
    }
    return ml ? '${diff.inDays} ദിവസം മുമ്പ്' : '${diff.inDays}d ago';
  }
}

/// Badge list result for a single child.
class ChildBadgeData {
  final int earned;
  final int total;
  final List<ChildBadge> badges;
  const ChildBadgeData({
    required this.earned,
    required this.total,
    required this.badges,
  });
}

/// Live progress payload for a child.
class ChildProgress {
  final String period;
  final int totalMarks;
  final int completionPct;
  final List<ProgressDay> series;
  final List<ProgressCategory> breakdown;
  const ChildProgress({
    required this.period,
    required this.totalMarks,
    required this.completionPct,
    required this.series,
    required this.breakdown,
  });
}

class ProgressDay {
  final String date;
  final int marks;
  final int completed;
  final int total;
  final int pct;
  const ProgressDay({
    required this.date,
    required this.marks,
    required this.completed,
    required this.total,
    required this.pct,
  });
}

class ProgressCategory {
  final String category;
  final String categoryMl;
  final int marks;
  const ProgressCategory({
    required this.category,
    required this.categoryMl,
    required this.marks,
  });
}

class LeaderEntry {
  final int rank;
  final String name;
  final String nameMl;
  final int marks;
  final bool isSelf;
  const LeaderEntry({
    required this.rank,
    required this.name,
    required this.nameMl,
    required this.marks,
    required this.isSelf,
  });
}
