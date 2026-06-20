import 'package:flutter/foundation.dart';

import '../model/app_models.dart';
import '../services/admin_api_client.dart';
import '../services/admin_repository.dart';
import '../services/google_auth_service.dart';

/// Central application state for the Alif admin panel.
///
/// Wraps the [AdminRepository] and exposes the loaded [AdminAppState] together
/// with navigation and authentication state to the widget tree via
/// `provider`'s [ChangeNotifier] mechanism.
class AdminProvider extends ChangeNotifier {
  AdminProvider({AdminApiClient? apiClient})
    : _apiClient = apiClient ?? AdminApiClient() {
    _repository = AdminRepository(_apiClient);
    _initialize();
  }

  static const bool _forceBypassLogin = bool.fromEnvironment(
    'BYPASS_ADMIN_LOGIN',
    defaultValue: false,
  );

  static const List<AdminSection> _navigationSections = [
    AdminSection.dashboard,
    AdminSection.students,
    AdminSection.teachers,
    AdminSection.batches,
    AdminSection.activities,
    AdminSection.rating,
    AdminSection.badges,
    AdminSection.notifications,
    AdminSection.reports,
  ];

  final AdminApiClient _apiClient;
  late final AdminRepository _repository;

  AdminAppState? _state;
  bool _isLoggedIn = false;
  bool _loading = true;
  AdminSection _selectedSection = AdminSection.dashboard;

  AdminAppState? get state => _state;
  bool get isLoggedIn => _isLoggedIn;
  bool get loading => _loading;
  AdminSection get selectedSection => _selectedSection;
  List<AdminSection> get navigationSections => _navigationSections;

  void _initialize() {
    if (_forceBypassLogin) {
      _isLoggedIn = true;
      _loading = true;
      loadState();
    } else {
      _loading = false;
    }
  }

  void selectSection(AdminSection section) {
    _selectedSection = section;
    notifyListeners();
  }

  Future<void> handleLoginSuccess(String token) async {
    _apiClient.setAuthToken(token);
    _isLoggedIn = true;
    _loading = true;
    notifyListeners();
    await loadState();
  }

  Future<void> handleLogout() async {
    try {
      await AdminAuthService.signOut();
    } finally {
      _apiClient.clearAuthToken();
    }

    _isLoggedIn = false;
    _loading = false;
    _state = null;
    _selectedSection = AdminSection.dashboard;
    notifyListeners();
  }

  Future<void> loadState() async {
    final state = await _repository.loadState();
    _state = state;
    _loading = false;
    notifyListeners();
  }

  Future<void> addStudent(StudentRecord student) async {
    _state?.students.insert(0, student);
    notifyListeners();
    try {
      await _repository.createStudent(student);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> updateStudent(StudentRecord student) async {
    final list = _state?.students;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == student.id);
      if (index >= 0) list[index] = student;
    }
    notifyListeners();
    try {
      await _repository.updateStudentRecord(student);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> deleteStudent(String studentId) async {
    _state?.students.removeWhere((item) => item.id == studentId);
    notifyListeners();
    try {
      await _repository.deleteStudentRecord(studentId);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> addTeacher(TeacherRecord teacher) async {
    _state?.teachers.insert(0, teacher);
    notifyListeners();
    try {
      await _repository.createTeacher(teacher);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> updateTeacher(TeacherRecord teacher) async {
    final list = _state?.teachers;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == teacher.id);
      if (index >= 0) list[index] = teacher;
    }
    notifyListeners();
    try {
      await _repository.updateTeacherRecord(teacher);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    _state?.teachers.removeWhere((item) => item.id == teacherId);
    notifyListeners();
    try {
      await _repository.deleteTeacherRecord(teacherId);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> addBatch(BatchClassRecord batch) async {
    _state?.batchClasses.insert(0, batch);
    notifyListeners();
    try {
      await _repository.createBatch(batch);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> updateBatch(BatchClassRecord batch) async {
    final list = _state?.batchClasses;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == batch.id);
      if (index >= 0) list[index] = batch;
    }
    notifyListeners();
    try {
      await _repository.updateBatchRecord(batch);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> deleteBatch(String batchId) async {
    _state?.batchClasses.removeWhere((item) => item.id == batchId);
    notifyListeners();
    try {
      await _repository.deleteBatchRecord(batchId);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> addActivity(ActivityRule activity) async {
    _state?.activities.add(activity);
    notifyListeners();
    try {
      await _repository.createActivity(activity);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> updateActivity(ActivityRule activity) async {
    final list = _state?.activities;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == activity.id);
      if (index >= 0) list[index] = activity;
    }
    notifyListeners();
    try {
      await _repository.updateActivityRecord(activity);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> deleteActivity(String activityId) async {
    _state?.activities.removeWhere((item) => item.id == activityId);
    notifyListeners();
    try {
      await _repository.deleteActivityRecord(activityId);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> addRatingRule(RatingRule rule) async {
    if (rule.isDefault) _clearDefaultRating();
    _state?.ratingRules.add(rule);
    notifyListeners();
    try {
      await _repository.createRatingRule(rule);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> updateRatingRule(RatingRule rule) async {
    if (rule.isDefault) _clearDefaultRating(exceptId: rule.id);
    final list = _state?.ratingRules;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == rule.id);
      if (index >= 0) list[index] = rule;
    }
    notifyListeners();
    try {
      await _repository.updateRatingRule(rule);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> deleteRatingRule(String ruleId) async {
    _state?.ratingRules.removeWhere((item) => item.id == ruleId);
    notifyListeners();
    try {
      await _repository.deleteRatingRule(ruleId);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  void _clearDefaultRating({String? exceptId}) {
    for (final rule in _state?.ratingRules ?? const <RatingRule>[]) {
      if (rule.id != exceptId) rule.isDefault = false;
    }
  }

  Future<void> addNotification(NotificationCampaign campaign) async {
    _state?.notifications.insert(0, campaign);
    notifyListeners();
    try {
      await _repository.createNotification(campaign);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> updateNotification(NotificationCampaign campaign) async {
    final list = _state?.notifications;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == campaign.id);
      if (index >= 0) list[index] = campaign;
    }
    notifyListeners();
    try {
      await _repository.updateNotificationRecord(campaign);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _state?.notifications.removeWhere((item) => item.id == notificationId);
    notifyListeners();
    try {
      await _repository.deleteNotificationRecord(notificationId);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> addBadge(BadgeDefinition badge) async {
    _state?.badges.add(badge);
    notifyListeners();
    try {
      await _repository.createBadge(badge);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> updateBadge(BadgeDefinition badge) async {
    final list = _state?.badges;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == badge.id);
      if (index >= 0) list[index] = badge;
    }
    notifyListeners();
    try {
      await _repository.updateBadgeRecord(badge);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }

  Future<void> deleteBadge(String badgeId) async {
    _state?.badges.removeWhere((item) => item.id == badgeId);
    notifyListeners();
    try {
      await _repository.deleteBadgeRecord(badgeId);
    } catch (_) {
      // Optimistic update kept for demo / offline mode.
    }
  }
}
