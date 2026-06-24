enum AdminSection {
  dashboard('Admin Dashboard', 'System overview and approvals'),
  students('Student Management', 'Search, approve, and promote students'),
  teachers('Teacher Management', 'Verification and class assignment'),
  batches('Batch/Class Management', 'Roster planning and ownership'),
  activities('Activity Configuration', 'Rules, categories, and approvals'),
  rating('Rating/Scoring', 'Score bands and defaults'),
  reports('Reports Dashboard', 'Operational insights and exports'),
  notifications('Notification Management', 'Campaign planning and approval'),
  badges('Badge Management', 'Recognition logic and publishing');

  const AdminSection(this.label, this.description);

  final String label;
  final String description;
}

enum RecordStatus { active, review, archived }

enum CampaignStatus { draft, scheduled, sent }

enum Gender { male, female }

/// Student record aligned with the FRP "Add Student" form (Sec 4.1.2).
class StudentRecord {
  StudentRecord({
    required this.id,
    required this.name,
    this.mobile = '',
    this.email = '',
    this.fatherName = '',
    this.motherName = '',
    this.dateOfBirth,
    this.gender = Gender.male,
    required this.batch,
    this.className = '',
    this.address = '',
    this.photoUrl = '',
    this.guardianName = '',
    this.score = 0,
    this.streak = 0,
    this.status = RecordStatus.active,
    this.enrollmentDate,
  });

  final String id;
  String name;
  String mobile;
  String email;
  String fatherName;
  String motherName;
  DateTime? dateOfBirth;
  Gender gender;
  String batch;
  String className;
  String address;
  String photoUrl;
  String guardianName;
  int score;
  int streak;
  RecordStatus status;
  DateTime? enrollmentDate;
}

/// Teacher record aligned with the FRP "Add Teacher" form (Sec 4.2).
class TeacherRecord {
  TeacherRecord({
    required this.id,
    required this.name,
    this.mobile = '',
    this.email = '',
    this.qualification = '',
    this.subjects = const [],
    this.batches = const [],
    this.photoUrl = '',
    this.status = RecordStatus.active,
  });

  final String id;
  String name;
  String mobile;
  String email;
  String qualification;
  List<String> subjects;
  List<String> batches;
  String photoUrl;
  RecordStatus status;
}

/// Batch record aligned with the FRP "Batch Management" form (Sec 4.3).
class BatchClassRecord {
  BatchClassRecord({
    required this.id,
    required this.name,
    this.className = '',
    this.teacherId = '',
    this.teacherName = '',
    this.studentCount = 0,
    this.schedule = '',
    this.capacity = 30,
    this.status = RecordStatus.active,
  });

  final String id;
  String name;
  String className;
  String teacherId;
  String teacherName;
  int studentCount;
  String schedule;
  int capacity;
  RecordStatus status;
}

/// Activity record aligned with the FRP "Activity Configuration" (Sec 4.4).
class ActivityRule {
  ActivityRule({
    required this.id,
    required this.name,
    this.category = '',
    this.points = 0,
    this.hasQuantity = false,
    this.isActive = true,
  });

  final String id;
  String name;
  String category;
  int points;
  bool hasQuantity;
  bool isActive;
}

/// Rating band aligned with the FRP "Rating/Scoring" configuration (Sec 4.5).
class RatingRule {
  RatingRule({
    required this.id,
    required this.label,
    this.minScore = 0,
    this.maxScore = 100,
    this.colorName = 'Green',
    this.isDefault = false,
    this.activityId = '',
    this.activityName = '',
  });

  final String id;
  String label;
  int minScore;
  int maxScore;
  String colorName;
  bool isDefault;
  String activityId;
  String activityName;
}

class ReportSnapshot {
  ReportSnapshot({
    required this.title,
    required this.value,
    required this.change,
    required this.trendLabel,
  });

  final String title;
  final String value;
  final String change;
  final String trendLabel;
}

/// Notification campaign aligned with the FRP "Notifications" compose
/// (Sec 4.7). Targets all / batch / class / student and can be scheduled.
class NotificationCampaign {
  NotificationCampaign({
    required this.id,
    required this.title,
    this.message = '',
    this.audience = '',
    this.scheduledFor = '',
    this.status = CampaignStatus.draft,
  });

  final String id;
  String title;
  String message;
  String audience;
  String scheduledFor;
  CampaignStatus status;
}

/// Badge definition aligned with the FRP "Badges" configuration (Sec 4.6).
class BadgeDefinition {
  BadgeDefinition({
    required this.id,
    required this.name,
    this.criteria = '',
    this.icon = '🏅',
    this.bonusPoints = 0,
    this.recipientCount = 0,
    this.isActive = true,
  });

  final String id;
  String name;
  String criteria;
  String icon;
  int bonusPoints;
  int recipientCount;
  bool isActive;
}

class AdminAppState {
  AdminAppState({
    required this.students,
    required this.teachers,
    required this.batchClasses,
    required this.activities,
    required this.ratingRules,
    required this.reports,
    required this.notifications,
    required this.badges,
    this.classes = const [],
  });

  final List<StudentRecord> students;
  final List<TeacherRecord> teachers;
  final List<BatchClassRecord> batchClasses;
  final List<ActivityRule> activities;
  final List<RatingRule> ratingRules;
  final List<ReportSnapshot> reports;
  final List<NotificationCampaign> notifications;
  final List<BadgeDefinition> badges;

  /// Distinct class names available for assignment (Add/Edit Student form).
  final List<String> classes;
}
