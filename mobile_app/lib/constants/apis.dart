/// Centralized API endpoint definitions for the Alif mobile app.
///
/// Keeping every endpoint in one place follows the project architecture and
/// makes it easy to update the base URL or paths in a single location.
class Apis {
  Apis._();

  /// Base URL for the backend API.
  ///
  /// Read from the `API_BASE_URL` compile-time environment so the same build
  /// can target localhost (web/desktop) or the PC's LAN IP (physical device)
  /// via `--dart-define=API_BASE_URL=...`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // ===== Authentication =====
  static String requestOtp() => '$baseUrl/auth/request-otp';
  static String verifyOtp() => '$baseUrl/auth/verify-otp';

  // ===== Daily records =====
  static String dailyRecords() => '$baseUrl/daily-records';
  static String dailyRecord(String recordId) =>
      '$baseUrl/daily-records/$recordId';
  static String submitDailyRecord(String recordId) =>
      '$baseUrl/daily-records/$recordId/submit';

  // ===== Activities =====
  static String dailyStructure() => '$baseUrl/activities/structure/daily';
  static String activities() => '$baseUrl/activities';

  // ===== Progress =====
  static String dailyProgress(String studentId) =>
      '$baseUrl/students/$studentId/progress/daily';
  static String weeklyProgress(String studentId) =>
      '$baseUrl/students/$studentId/progress/weekly';
  static String monthlyProgress(String studentId) =>
      '$baseUrl/students/$studentId/progress/monthly';

  // ===== Leaderboard =====
  static String leaderboard(String batchId) =>
      '$baseUrl/batches/$batchId/leaderboard';
  static String weeklyLeaderboard(String batchId) =>
      '$baseUrl/batches/$batchId/leaderboard/weekly';

  // ===== Notifications =====
  static String parentNotifications() => '$baseUrl/parents/me/notifications';
  static String studentNotifications() => '$baseUrl/students/me/notifications';
}
