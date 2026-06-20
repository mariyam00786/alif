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

      return TeacherBatchAnalytics(
        studentCount: (data['student_count'] as num?)?.toInt() ?? 0,
        activeToday: (data['active_today'] as num?)?.toInt() ?? 0,
        avgCompletion: (data['avg_completion'] as num?)?.toInt() ?? 0,
        topPerformers: performers,
        areasToImprove: areas,
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

  const TeacherBatchAnalytics({
    required this.studentCount,
    required this.activeToday,
    required this.avgCompletion,
    required this.topPerformers,
    required this.areasToImprove,
  });
}
