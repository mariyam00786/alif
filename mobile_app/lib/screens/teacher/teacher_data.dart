import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';

/// A batch assigned to the signed-in teacher.
class TeacherBatch {
  final String id;
  final String name;
  final String nameMl;
  final int studentCount;
  final int activeToday;
  final int avgCompletion; // 0-100 average completion % for today
  final Color color;

  const TeacherBatch({
    required this.id,
    required this.name,
    required this.nameMl,
    required this.studentCount,
    required this.activeToday,
    required this.avgCompletion,
    required this.color,
  });
}

/// A student under one of the teacher's batches.
class TeacherStudent {
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
  final int badges;
  final bool loggedToday;
  final String lastSeen;
  final String lastSeenMl;

  const TeacherStudent({
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
    required this.badges,
    required this.loggedToday,
    required this.lastSeen,
    required this.lastSeenMl,
  });

  /// Whether this student needs the teacher's attention
  /// (no log today or low weekly performance).
  bool get needsAttention => !loggedToday || weekPct < 50;
}

/// A remark / feedback left by the teacher for a student.
class StudentRemark {
  final String id;
  final String studentId;
  final String message;
  final String dateLabel;
  final String dateLabelMl;

  const StudentRemark({
    required this.id,
    required this.studentId,
    required this.message,
    required this.dateLabel,
    required this.dateLabelMl,
  });
}

/// A per-category breakdown row used in student progress + batch analytics.
class CategoryScore {
  final String title;
  final String titleMl;
  final IconData icon;
  final Color color;
  final int pct; // 0-100

  const CategoryScore({
    required this.title,
    required this.titleMl,
    required this.icon,
    required this.color,
    required this.pct,
  });
}

/// Central mock data source for the teacher portal.
///
/// Mirrors the inline-mock pattern used by the student/parent screens. When
/// the teacher backend endpoints are wired, replace these getters with API
/// calls (see FRD §6.4).
class TeacherData {
  TeacherData._();

  /// True once live API data has replaced the demo defaults below.
  static bool isLive = false;

  static String teacherName = 'Ustad Yusuf';
  static String teacherNameMl = 'ഉസ്താദ് യൂസഫ്';

  static List<TeacherBatch> batches = [
    TeacherBatch(
      id: 'batch-001',
      name: 'Noor Batch',
      nameMl: 'നൂർ ബാച്ച്',
      studentCount: 24,
      activeToday: 19,
      avgCompletion: 78,
      color: Color(0xFF1B6B3A),
    ),
    TeacherBatch(
      id: 'batch-002',
      name: 'Iman Batch',
      nameMl: 'ഈമാൻ ബാച്ച്',
      studentCount: 18,
      activeToday: 11,
      avgCompletion: 61,
      color: Color(0xFF1565C0),
    ),
    TeacherBatch(
      id: 'batch-003',
      name: 'Falah Batch',
      nameMl: 'ഫലാഹ് ബാച്ച്',
      studentCount: 21,
      activeToday: 17,
      avgCompletion: 72,
      color: Color(0xFF8E24AA),
    ),
  ];

  static List<TeacherStudent> students = [
    TeacherStudent(
      id: 'student-001',
      name: 'Ahmed Ali',
      nameMl: 'അഹമ്മദ് അലി',
      batchId: 'batch-001',
      batchName: 'Noor Batch',
      batchNameMl: 'നൂർ ബാച്ച്',
      avatar: 'A',
      color: Color(0xFF1B6B3A),
      todayMarks: 85,
      todayPct: 92,
      weekPct: 88,
      monthPct: 84,
      rank: 1,
      badges: 6,
      loggedToday: true,
      lastSeen: 'Today, 7:40 AM',
      lastSeenMl: 'ഇന്ന്, 7:40 AM',
    ),
    TeacherStudent(
      id: 'student-002',
      name: 'Fatima Noor',
      nameMl: 'ഫാത്തിമ നൂർ',
      batchId: 'batch-001',
      batchName: 'Noor Batch',
      batchNameMl: 'നൂർ ബാച്ച്',
      avatar: 'F',
      color: Color(0xFFAD1457),
      todayMarks: 72,
      todayPct: 80,
      weekPct: 76,
      monthPct: 79,
      rank: 3,
      badges: 4,
      loggedToday: true,
      lastSeen: 'Today, 8:10 AM',
      lastSeenMl: 'ഇന്ന്, 8:10 AM',
    ),
    TeacherStudent(
      id: 'student-003',
      name: 'Bilal Rahman',
      nameMl: 'ബിലാൽ റഹ്മാൻ',
      batchId: 'batch-001',
      batchName: 'Noor Batch',
      batchNameMl: 'നൂർ ബാച്ച്',
      avatar: 'B',
      color: Color(0xFF1565C0),
      todayMarks: 0,
      todayPct: 0,
      weekPct: 41,
      monthPct: 52,
      rank: 18,
      badges: 1,
      loggedToday: false,
      lastSeen: 'Yesterday',
      lastSeenMl: 'ഇന്നലെ',
    ),
    TeacherStudent(
      id: 'student-004',
      name: 'Mariam Shifa',
      nameMl: 'മറിയം ഷിഫ',
      batchId: 'batch-002',
      batchName: 'Iman Batch',
      batchNameMl: 'ഈമാൻ ബാച്ച്',
      avatar: 'M',
      color: Color(0xFF8E24AA),
      todayMarks: 64,
      todayPct: 70,
      weekPct: 68,
      monthPct: 71,
      rank: 5,
      badges: 3,
      loggedToday: true,
      lastSeen: 'Today, 6:55 AM',
      lastSeenMl: 'ഇന്ന്, 6:55 AM',
    ),
    TeacherStudent(
      id: 'student-005',
      name: 'Yusuf Khan',
      nameMl: 'യൂസഫ് ഖാൻ',
      batchId: 'batch-002',
      batchName: 'Iman Batch',
      batchNameMl: 'ഈമാൻ ബാച്ച്',
      avatar: 'Y',
      color: Color(0xFFEF6C00),
      todayMarks: 0,
      todayPct: 0,
      weekPct: 33,
      monthPct: 44,
      rank: 22,
      badges: 0,
      loggedToday: false,
      lastSeen: '3 days ago',
      lastSeenMl: '3 ദിവസം മുമ്പ്',
    ),
    TeacherStudent(
      id: 'student-006',
      name: 'Aisha Beevi',
      nameMl: 'ആയിഷ ബീവി',
      batchId: 'batch-003',
      batchName: 'Falah Batch',
      batchNameMl: 'ഫലാഹ് ബാച്ച്',
      avatar: 'A',
      color: Color(0xFF00897B),
      todayMarks: 78,
      todayPct: 86,
      weekPct: 82,
      monthPct: 80,
      rank: 2,
      badges: 5,
      loggedToday: true,
      lastSeen: 'Today, 7:05 AM',
      lastSeenMl: 'ഇന്ന്, 7:05 AM',
    ),
  ];

  /// Remarks keyed loosely by student; returns the full list for the mock.
  static List<StudentRemark> remarks = [
    StudentRemark(
      id: 'remark-001',
      studentId: 'student-003',
      message: 'Please log your Fajr prayer on time. Keep it up!',
      dateLabel: '2 days ago',
      dateLabelMl: '2 ദിവസം മുമ്പ്',
    ),
    StudentRemark(
      id: 'remark-002',
      studentId: 'student-001',
      message: 'Excellent consistency this week, mashaAllah.',
      dateLabel: '1 day ago',
      dateLabelMl: '1 ദിവസം മുമ്പ്',
    ),
  ];

  /// Per-category breakdown for a student's progress view (mock).
  static const List<CategoryScore> studentCategories = [
    CategoryScore(
      title: 'Prayer',
      titleMl: 'നമസ്കാരം',
      icon: Icons.mosque_rounded,
      color: Color(0xFF1B6B3A),
      pct: 88,
    ),
    CategoryScore(
      title: 'Sunnah Prayers',
      titleMl: 'സുന്നത്ത് നമസ്കാരം',
      icon: Icons.brightness_5_rounded,
      color: Color(0xFFEF6C00),
      pct: 64,
    ),
    CategoryScore(
      title: 'Daily Routine',
      titleMl: 'ദിനചര്യ',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF1565C0),
      pct: 73,
    ),
  ];

  /// Batch-level category averages used by the analytics screen (mock).
  static const List<CategoryScore> batchCategories = [
    CategoryScore(
      title: 'Prayer',
      titleMl: 'നമസ്കാരം',
      icon: Icons.mosque_rounded,
      color: Color(0xFF1B6B3A),
      pct: 81,
    ),
    CategoryScore(
      title: 'Sunnah Prayers',
      titleMl: 'സുന്നത്ത് നമസ്കാരം',
      icon: Icons.brightness_5_rounded,
      color: Color(0xFFEF6C00),
      pct: 58,
    ),
    CategoryScore(
      title: 'Daily Routine',
      titleMl: 'ദിനചര്യ',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF1565C0),
      pct: 69,
    ),
  ];

  /// Notifications shown in the teacher header bell (mock).
  static List<PortalNotification> notifications() => const [
    PortalNotification(
      title: 'Achievement unlocked',
      titleMl: 'നേട്ടം ലഭിച്ചു',
      body: 'Ahmed Ali earned the 30-Day Streak badge.',
      bodyMl: 'അഹമ്മദ് അലി 30-ദിന സ്ട്രീക് ബാഡ്ജ് നേടി.',
      timeAgo: '10m ago',
      timeAgoMl: '10 മിനിറ്റ് മുമ്പ്',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFA000),
      unread: true,
    ),
    PortalNotification(
      title: 'Low activity alert',
      titleMl: 'കുറഞ്ഞ പ്രവർത്തനം',
      body: '2 students in Iman Batch have not logged today.',
      bodyMl: 'ഈമാൻ ബാച്ചിലെ 2 വിദ്യാർഥികൾ ഇന്ന് ലോഗ് ചെയ്തിട്ടില്ല.',
      timeAgo: '1h ago',
      timeAgoMl: '1 മണിക്കൂർ മുമ്പ്',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFEF6C00),
      unread: true,
    ),
    PortalNotification(
      title: 'Weekly report ready',
      titleMl: 'പ്രതിവാര റിപ്പോർട്ട് തയ്യാർ',
      body: 'Noor Batch weekly summary is available.',
      bodyMl: 'നൂർ ബാച്ചിന്റെ പ്രതിവാര സംഗ്രഹം ലഭ്യമാണ്.',
      timeAgo: 'Yesterday',
      timeAgoMl: 'ഇന്നലെ',
      icon: Icons.insights_rounded,
      color: Color(0xFF1B6B3A),
    ),
  ];

  // ===== Derived helpers =====

  static int get totalStudents =>
      batches.fold(0, (sum, b) => sum + b.studentCount);

  static int get activeToday =>
      batches.fold(0, (sum, b) => sum + b.activeToday);

  static int get avgCompletion {
    if (batches.isEmpty) return 0;
    final total = batches.fold(0, (sum, b) => sum + b.avgCompletion);
    return (total / batches.length).round();
  }

  static List<TeacherStudent> get needsAttention =>
      students.where((s) => s.needsAttention).toList();

  static List<TeacherStudent> studentsForBatch(String batchId) =>
      students.where((s) => s.batchId == batchId).toList();

  static List<StudentRemark> remarksForStudent(String studentId) =>
      remarks.where((r) => r.studentId == studentId).toList();
}
