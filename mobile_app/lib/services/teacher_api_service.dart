import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/apis.dart';
import '../screens/teacher/teacher_data.dart';
import 'api_service.dart';

/// Live API client for the teacher portal.
///
/// Talks to the backend `/api/teacher/*` endpoints (FRD §6.4), reusing the
/// auth token stored by [MobileApiService] after sign-in. Responses are mapped
/// onto the UI model classes used by the teacher screens. On any failure the
/// caller keeps the existing (demo) data, so the portal still renders offline.
class TeacherApiService {
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
    Color(0xFF1565C0),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFFAD1457),
    Color(0xFFEF6C00),
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

  // ===== Dashboard refresh (batches + students) =====

  /// Loads assigned batches and students from the backend and populates
  /// [TeacherData]. Returns true on success, false if it fell back to demo
  /// data (no token, or a network/API error).
  static Future<bool> refresh() async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return false;

    try {
      final batchesRes = await http
          .get(Uri.parse('$_base/teacher/batches'), headers: _headers())
          .timeout(_timeout);
      final studentsRes = await http
          .get(Uri.parse('$_base/teacher/students'), headers: _headers())
          .timeout(_timeout);

      final batches = _list(
        batchesRes,
      ).map((e) => _mapBatch(e as Map<String, dynamic>)).toList();
      final students = _list(
        studentsRes,
      ).map((e) => _mapStudent(e as Map<String, dynamic>)).toList();

      if (batches.isEmpty && students.isEmpty) return false;

      TeacherData.batches = batches;
      TeacherData.students = students;
      TeacherData.isLive = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static TeacherBatch _mapBatch(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? '';
    final name = j['name']?.toString() ?? 'Batch';
    return TeacherBatch(
      id: id,
      name: name,
      nameMl: (j['name_ml']?.toString().isNotEmpty ?? false)
          ? j['name_ml'].toString()
          : name,
      studentCount: (j['student_count'] as num?)?.toInt() ?? 0,
      activeToday: (j['active_today'] as num?)?.toInt() ?? 0,
      avgCompletion: (j['avg_completion'] as num?)?.toInt() ?? 0,
      color: _colorFor(id),
    );
  }

  static TeacherStudent _mapStudent(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? '';
    final name = j['name']?.toString() ?? 'Student';
    final loggedToday = j['logged_today'] == true;
    return TeacherStudent(
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
      badges: (j['badges'] as num?)?.toInt() ?? 0,
      loggedToday: loggedToday,
      lastSeen: loggedToday ? 'Today' : 'Not logged today',
      lastSeenMl: loggedToday ? 'ഇന്ന്' : 'ഇന്ന് ലോഗ് ഇല്ല',
    );
  }

  // ===== Student progress + remarks =====

  /// Fetches a student's weekly/monthly progress with category breakdown and
  /// remarks. Returns null on failure so the caller can fall back to demo data.
  static Future<TeacherStudentProgress?> fetchStudentProgress(
    String studentId, {
    required bool monthly,
  }) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;

    try {
      final period = monthly ? 'monthly' : 'weekly';
      final res = await http
          .get(
            Uri.parse(
              '$_base/teacher/student/$studentId/progress?period=$period',
            ),
            headers: _headers(),
          )
          .timeout(_timeout);
      final data = _object(res);

      final breakdown = ((data['breakdown'] as List?) ?? const [])
          .map((e) => _mapCategory(e as Map<String, dynamic>))
          .toList();
      final remarks = ((data['remarks'] as List?) ?? const [])
          .map((e) => _mapRemark(studentId, e as Map<String, dynamic>))
          .toList();

      return TeacherStudentProgress(
        completionPct: (data['completion_pct'] as num?)?.toInt() ?? 0,
        totalMarks: (data['total_marks'] as num?)?.toInt() ?? 0,
        categories: breakdown,
        remarks: remarks,
      );
    } catch (_) {
      return null;
    }
  }

  /// Posts a new remark for a student. Returns the created [StudentRemark],
  /// or null if the call failed (e.g. demo mode).
  static Future<StudentRemark?> addRemark(
    String studentId,
    String message,
  ) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;

    try {
      final res = await http
          .post(
            Uri.parse('$_base/teacher/student/$studentId/remark'),
            headers: _headers(),
            body: jsonEncode({'message': message}),
          )
          .timeout(_timeout);
      final data = _object(res);
      return _mapRemark(studentId, data);
    } catch (_) {
      return null;
    }
  }

  // ===== Badges (teacher-awarded recognition) =====

  /// Loads the catalogue of awardable badges. Returns empty list on failure.
  static Future<List<TeacherBadge>> fetchBadges() async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return const [];
    try {
      final res = await http
          .get(Uri.parse('$_base/teacher/badges'), headers: _headers())
          .timeout(_timeout);
      return _list(res).map((e) => _mapBadge(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Loads the badges already awarded to a student.
  static Future<List<TeacherBadge>> fetchStudentBadges(String studentId) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return const [];
    try {
      final res = await http
          .get(
            Uri.parse('$_base/teacher/student/$studentId/badges'),
            headers: _headers(),
          )
          .timeout(_timeout);
      return _list(res).map((e) => _mapBadge(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Awards a badge to a student. Returns the awarded [TeacherBadge] or null.
  static Future<TeacherBadge?> awardBadge(
    String studentId,
    String badgeId,
  ) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;
    try {
      final res = await http
          .post(
            Uri.parse('$_base/teacher/student/$studentId/badge'),
            headers: _headers(),
            body: jsonEncode({'badge_id': badgeId}),
          )
          .timeout(_timeout);
      return _mapBadge(_object(res));
    } catch (_) {
      return null;
    }
  }

  static TeacherBadge _mapBadge(Map<String, dynamic> j) {
    final name = j['name']?.toString() ?? 'Badge';
    return TeacherBadge(
      id: j['badge_id']?.toString() ?? j['id']?.toString() ?? '',
      name: name,
      nameMl: (j['name_ml']?.toString().isNotEmpty ?? false)
          ? j['name_ml'].toString()
          : name,
      icon: j['icon']?.toString() ?? '🏅',
      bonusPoints: (j['bonus_points'] as num?)?.toInt() ?? 0,
      awardedBy: j['awarded_by']?.toString(),
      awardedByName: j['awarded_by_name']?.toString(),
      earnedAt: j['earned_at']?.toString(),
    );
  }

  // ===== Teacher-sent notifications (Phase T / FRD §4.3.4) =====

  /// Sends a batch reminder / motivational / acknowledgement to a batch.
  ///
  /// Returns the created row (with `recipients`) on success, or null on
  /// failure / demo mode.
  static Future<TeacherNotificationResult?> notifyBatch(
    String batchId, {
    required String title,
    required String body,
    required String type, // batch_reminder | motivational | acknowledgement
  }) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;
    try {
      final res = await http
          .post(
            Uri.parse('$_base/teacher/batch/$batchId/notify'),
            headers: _headers(),
            body: jsonEncode({'title': title, 'body': body, 'type': type}),
          )
          .timeout(_timeout);
      final data = _object(res);
      return TeacherNotificationResult(
        id: data['id']?.toString() ?? '',
        batchId: data['batch_id']?.toString() ?? batchId,
        recipients: (data['recipients'] as num?)?.toInt() ?? 0,
        title: data['title']?.toString() ?? title,
        body: data['body']?.toString() ?? body,
        type: data['type']?.toString() ?? type,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch announcements + batch reminders for the signed-in teacher (T2 bell).
  static Future<List<Map<String, dynamic>>> fetchTeacherNotifications() async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return const [];
    try {
      final res = await http
          .get(
            Uri.parse('$_base/teacher/me/notifications'),
            headers: _headers(),
          )
          .timeout(_timeout);
      final list = _list(res);
      return list
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ===== Per-student monitoring extras (T4) =====

  /// Loads the last [days] days of attendance for a student. Returns null on
  /// failure / demo mode.
  static Future<StudentAttendanceHistory?> fetchStudentAttendanceHistory(
    String studentId, {
    int days = 30,
  }) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_base/teacher/student/$studentId/attendance?days=$days',
            ),
            headers: _headers(),
          )
          .timeout(_timeout);
      final data = _object(res);
      final entries = ((data['entries'] as List?) ?? const [])
          .map((e) => AttendanceHistoryEntry(
                date: (e as Map<String, dynamic>)['date']?.toString() ?? '',
                status: e['status']?.toString(),
                notes: e['notes']?.toString(),
                markedByName: e['marked_by_name']?.toString(),
              ))
          .toList();
      return StudentAttendanceHistory(
        fromDate: data['from_date']?.toString() ?? '',
        toDate: data['to_date']?.toString() ?? '',
        presentCount: (data['present_count'] as num?)?.toInt() ?? 0,
        totalMarked: (data['total_marked'] as num?)?.toInt() ?? 0,
        entries: entries,
      );
    } catch (_) {
      return null;
    }
  }

  // ===== Class management (T5) =====

  /// Loads the classes for the teacher's assigned batches.
  static Future<List<TeacherClass>> fetchClasses() async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return const [];
    try {
      final res = await http
          .get(Uri.parse('$_base/teacher/classes'), headers: _headers())
          .timeout(_timeout);
      return _list(res)
          .map((e) => _mapClass(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Loads the roster for a class (students + today's attendance status).
  static Future<ClassRoster?> fetchClassRoster(
    String classId, {
    String? date,
  }) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;
    try {
      final q = date != null ? '?date=$date' : '';
      final res = await http
          .get(
            Uri.parse('$_base/teacher/class/$classId$q'),
            headers: _headers(),
          )
          .timeout(_timeout);
      final data = _object(res);
      final students = ((data['students'] as List?) ?? const [])
          .map((e) {
            final m = e as Map<String, dynamic>;
            final name = m['name']?.toString() ?? 'Student';
            return AttendanceRow(
              studentId: m['id']?.toString() ?? '',
              name: name,
              nameMl: (m['name_ml']?.toString().isNotEmpty ?? false)
                  ? m['name_ml'].toString()
                  : name,
              status: m['status']?.toString(),
            );
          })
          .toList();
      return ClassRoster(
        classId: data['class_id']?.toString() ?? classId,
        className: data['class_name']?.toString() ?? 'Class',
        classNameMl: data['class_name_ml']?.toString() ??
            data['class_name']?.toString() ??
            'Class',
        level: data['level']?.toString(),
        batchId: data['batch_id']?.toString(),
        batchName: data['batch_name']?.toString(),
        date: data['date']?.toString() ?? '',
        presentCount: (data['present_count'] as num?)?.toInt() ?? 0,
        total: (data['total'] as num?)?.toInt() ?? students.length,
        students: students,
      );
    } catch (_) {
      return null;
    }
  }

  static TeacherClass _mapClass(Map<String, dynamic> j) {
    final name = j['name']?.toString() ?? 'Class';
    return TeacherClass(
      id: j['id']?.toString() ?? '',
      name: name,
      nameMl: (j['name_ml']?.toString().isNotEmpty ?? false)
          ? j['name_ml'].toString()
          : name,
      level: j['level']?.toString(),
      batchId: j['batch_id']?.toString(),
      batchName: j['batch_name']?.toString(),
      studentCount: (j['student_count'] as num?)?.toInt() ?? 0,
    );
  }

  // ===== Attendance =====

  /// Loads attendance for a batch on a date. Returns null on failure.
  static Future<BatchAttendance?> fetchAttendance(
    String batchId, {
    String? date,
  }) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;
    try {
      final q = date != null ? '?date=$date' : '';
      final res = await http
          .get(
            Uri.parse('$_base/teacher/batch/$batchId/attendance$q'),
            headers: _headers(),
          )
          .timeout(_timeout);
      final data = _object(res);
      final students = ((data['students'] as List?) ?? const [])
          .map((e) {
            final m = e as Map<String, dynamic>;
            final name = m['name']?.toString() ?? 'Student';
            return AttendanceRow(
              studentId: m['id']?.toString() ?? '',
              name: name,
              nameMl: (m['name_ml']?.toString().isNotEmpty ?? false)
                  ? m['name_ml'].toString()
                  : name,
              status: m['status']?.toString(),
            );
          })
          .toList();
      return BatchAttendance(
        date: data['date']?.toString() ?? '',
        presentCount: (data['present_count'] as num?)?.toInt() ?? 0,
        total: (data['total'] as num?)?.toInt() ?? students.length,
        rows: students,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves attendance for one or more students in a batch on a date.
  /// Returns true on success.
  static Future<bool> saveAttendance(
    String batchId, {
    required List<({String studentId, String status})> entries,
    String? date,
  }) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return false;
    try {
      final res = await http
          .post(
            Uri.parse('$_base/teacher/batch/$batchId/attendance'),
            headers: _headers(),
            body: jsonEncode({
              'date': ?date,
              'entries': entries
                  .map((e) => {'student_id': e.studentId, 'status': e.status})
                  .toList(),
            }),
          )
          .timeout(_timeout);
      _object(res); // throws on non-2xx
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== Batch analytics =====

  /// Fetches analytics for a single batch. Returns null on failure.
  static Future<TeacherBatchAnalytics?> fetchBatchAnalytics(
    String batchId,
  ) async {
    final token = MobileApiService.getAuthToken();
    if (token == null || token == 'demo-teacher') return null;

    try {
      final res = await http
          .get(
            Uri.parse('$_base/teacher/batch/$batchId/analytics'),
            headers: _headers(),
          )
          .timeout(_timeout);
      final data = _object(res);

      final performers = ((data['top_performers'] as List?) ?? const [])
          .map(
            (e) => TeacherPerformer(
              id: (e as Map<String, dynamic>)['id']?.toString() ?? '',
              name: e['name']?.toString() ?? 'Student',
              nameMl: (e['name_ml']?.toString().isNotEmpty ?? false)
                  ? e['name_ml'].toString()
                  : (e['name']?.toString() ?? 'Student'),
              pct: (e['pct'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();
      final areas = ((data['areas_to_improve'] as List?) ?? const [])
          .map((e) => _mapCategory(e as Map<String, dynamic>))
          .toList();
      final weeklyTrend = ((data['weekly_trend'] as List?) ?? const [])
          .map(
            (e) => TeacherWeekTrend(
              weekStart: (e as Map<String, dynamic>)['week_start']?.toString() ?? '',
              weekEnd: e['week_end']?.toString() ?? '',
              completionPct: (e['completion_pct'] as num?)?.toInt() ?? 0,
              marks: (e['marks'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();
      final crossBatch = ((data['cross_batch_comparison'] as List?) ?? const [])
          .map(
            (e) => TeacherCrossBatchPoint(
              id: (e as Map<String, dynamic>)['id']?.toString() ?? '',
              name: e['name']?.toString() ?? 'Batch',
              nameMl: (e['name_ml']?.toString().isNotEmpty ?? false)
                  ? e['name_ml'].toString()
                  : (e['name']?.toString() ?? 'Batch'),
              studentCount: (e['student_count'] as num?)?.toInt() ?? 0,
              activeToday: (e['active_today'] as num?)?.toInt() ?? 0,
              avgCompletion: (e['avg_completion'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();

      return TeacherBatchAnalytics(
        studentCount: (data['student_count'] as num?)?.toInt() ?? 0,
        activeToday: (data['active_today'] as num?)?.toInt() ?? 0,
        avgCompletion: (data['avg_completion'] as num?)?.toInt() ?? 0,
        topPerformers: performers,
        areasToImprove: areas,
        weeklyTrend: weeklyTrend,
        crossBatch: crossBatch,
      );
    } catch (_) {
      return null;
    }
  }

  // ===== Mappers shared across endpoints =====

  static CategoryScore _mapCategory(Map<String, dynamic> j) {
    final title = j['category']?.toString() ?? 'Other';
    return CategoryScore(
      title: title,
      titleMl: (j['category_ml']?.toString().isNotEmpty ?? false)
          ? j['category_ml'].toString()
          : title,
      icon: _iconFor(j['icon']?.toString()),
      color: _colorFor(title),
      pct: (j['pct'] as num?)?.toInt() ?? 0,
    );
  }

  static StudentRemark _mapRemark(String studentId, Map<String, dynamic> j) {
    final createdAt = DateTime.tryParse(j['created_at']?.toString() ?? '');
    final label = _relativeDay(createdAt);
    return StudentRemark(
      id: j['id']?.toString() ?? '',
      studentId: studentId,
      message: j['message']?.toString() ?? '',
      dateLabel: label.en,
      dateLabelMl: label.ml,
    );
  }

  static IconData _iconFor(String? key) {
    switch (key) {
      case 'mosque':
        return Icons.mosque_rounded;
      case 'sun':
      case 'brightness':
        return Icons.brightness_5_rounded;
      case 'book':
      case 'quran':
        return Icons.menu_book_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  static ({String en, String ml}) _relativeDay(DateTime? when) {
    if (when == null) return (en: 'Recently', ml: 'അടുത്തിടെ');
    final days = DateTime.now().toUtc().difference(when.toUtc()).inDays;
    if (days <= 0) return (en: 'Today', ml: 'ഇന്ന്');
    if (days == 1) return (en: '1 day ago', ml: '1 ദിവസം മുമ്പ്');
    return (en: '$days days ago', ml: '$days ദിവസം മുമ്പ്');
  }
}

/// Live student progress payload from `/teacher/student/:id/progress`.
class TeacherStudentProgress {
  final int completionPct;
  final int totalMarks;
  final List<CategoryScore> categories;
  final List<StudentRemark> remarks;

  const TeacherStudentProgress({
    required this.completionPct,
    required this.totalMarks,
    required this.categories,
    required this.remarks,
  });
}

/// A ranked performer in `/teacher/batch/:id/analytics`.
class TeacherPerformer {
  final String id;
  final String name;
  final String nameMl;
  final int pct;

  const TeacherPerformer({
    required this.id,
    required this.name,
    required this.nameMl,
    required this.pct,
  });
}

/// Live batch analytics payload from `/teacher/batch/:id/analytics`.
class TeacherBatchAnalytics {
  final int studentCount;
  final int activeToday;
  final int avgCompletion;
  final List<TeacherPerformer> topPerformers;
  final List<CategoryScore> areasToImprove;
  final List<TeacherWeekTrend> weeklyTrend;
  final List<TeacherCrossBatchPoint> crossBatch;

  const TeacherBatchAnalytics({
    required this.studentCount,
    required this.activeToday,
    required this.avgCompletion,
    required this.topPerformers,
    required this.areasToImprove,
    this.weeklyTrend = const [],
    this.crossBatch = const [],
  });
}

/// One week of completion trend (Phase T / FRD §4.3.3 4-week trend line).
class TeacherWeekTrend {
  final String weekStart;
  final String weekEnd;
  final int completionPct;
  final int marks;

  const TeacherWeekTrend({
    required this.weekStart,
    required this.weekEnd,
    required this.completionPct,
    required this.marks,
  });
}

/// A cross-batch comparison point (Phase T / FRD §4.3.3 chart).
class TeacherCrossBatchPoint {
  final String id;
  final String name;
  final String nameMl;
  final int studentCount;
  final int activeToday;
  final int avgCompletion;

  const TeacherCrossBatchPoint({
    required this.id,
    required this.name,
    required this.nameMl,
    required this.studentCount,
    required this.activeToday,
    required this.avgCompletion,
  });
}

/// An awardable / awarded badge from `/teacher/badges`.
class TeacherBadge {
  final String id;
  final String name;
  final String nameMl;
  final String icon;
  final int bonusPoints;

  /// Teacher who awarded the badge (only populated for already-awarded
  /// badges returned by `/student/:id/badges`).
  final String? awardedBy;
  final String? awardedByName;
  final String? earnedAt;

  const TeacherBadge({
    required this.id,
    required this.name,
    required this.nameMl,
    required this.icon,
    required this.bonusPoints,
    this.awardedBy,
    this.awardedByName,
    this.earnedAt,
  });
}

/// One student's attendance status for a day.
class AttendanceRow {
  final String studentId;
  final String name;
  final String nameMl;
  final String? status; // present | absent | late | excused | null

  const AttendanceRow({
    required this.studentId,
    required this.name,
    required this.nameMl,
    required this.status,
  });
}

/// Attendance for a batch on a given date.
class BatchAttendance {
  final String date;
  final int presentCount;
  final int total;
  final List<AttendanceRow> rows;

  const BatchAttendance({
    required this.date,
    required this.presentCount,
    required this.total,
    required this.rows,
  });
}

/// Result of sending a batch notification (Phase T / FRD §4.3.4).
class TeacherNotificationResult {
  final String id;
  final String batchId;
  final int recipients;
  final String title;
  final String body;
  final String type;

  const TeacherNotificationResult({
    required this.id,
    required this.batchId,
    required this.recipients,
    required this.title,
    required this.body,
    required this.type,
  });
}

/// A student's attendance history over a window (Phase T / T4).
class StudentAttendanceHistory {
  final String fromDate;
  final String toDate;
  final int presentCount;
  final int totalMarked;
  final List<AttendanceHistoryEntry> entries;

  const StudentAttendanceHistory({
    required this.fromDate,
    required this.toDate,
    required this.presentCount,
    required this.totalMarked,
    required this.entries,
  });
}

/// One day's attendance in a student's history (Phase T / T4).
class AttendanceHistoryEntry {
  final String date;
  final String? status;
  final String? notes;
  final String? markedByName;

  const AttendanceHistoryEntry({
    required this.date,
    required this.status,
    required this.notes,
    this.markedByName,
  });
}

/// A class under one of the teacher's batches (Phase T / T5).
class TeacherClass {
  final String id;
  final String name;
  final String nameMl;
  final String? level;
  final String? batchId;
  final String? batchName;
  final int studentCount;

  const TeacherClass({
    required this.id,
    required this.name,
    required this.nameMl,
    required this.level,
    required this.batchId,
    required this.batchName,
    required this.studentCount,
  });
}

/// Roster + daily attendance for a class (Phase T / T5).
class ClassRoster {
  final String classId;
  final String className;
  final String classNameMl;
  final String? level;
  final String? batchId;
  final String? batchName;
  final String date;
  final int presentCount;
  final int total;
  final List<AttendanceRow> students;

  const ClassRoster({
    required this.classId,
    required this.className,
    required this.classNameMl,
    required this.level,
    required this.batchId,
    required this.batchName,
    required this.date,
    required this.presentCount,
    required this.total,
    required this.students,
  });
}
