/// Centralised API endpoint definitions for the admin panel.
///
/// The base URL can be overridden at build time with
/// `--dart-define=API_BASE_URL=...`.
class Apis {
  Apis._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String adminOverview = '/api/admin/overview';

  static String approveStudent(String studentId) =>
      '/api/admin/students/$studentId/approval';

  static String studentStatus(String studentId) =>
      '/api/admin/students/$studentId/status';

  static String approveTeacher(String teacherId) =>
      '/api/admin/teachers/$teacherId/approval';

  static String assignBatchTeacher(String batchId) =>
      '/api/admin/batches/$batchId/teacher';

  static String toggleActivity(String activityId) =>
      '/api/admin/activities/$activityId/active';

  static String ratingDefault(String ruleId) =>
      '/api/admin/rating-rules/$ruleId/default';

  static String notificationApproval(String notificationId) =>
      '/api/admin/notifications/$notificationId/approval';

  static String badgePublish(String badgeId) =>
      '/api/admin/badges/$badgeId/publish';
}
