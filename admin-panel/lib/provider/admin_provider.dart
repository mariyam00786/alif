import 'dart:async';

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
  String? _lastError;
  String? _lastInfo;

  bool _whatsAppChecked = false;
  bool _whatsAppConnected = true;
  String _whatsAppMessage = '';

  AdminAppState? get state => _state;
  bool get isLoggedIn => _isLoggedIn;
  bool get loading => _loading;
  AdminSection get selectedSection => _selectedSection;
  List<AdminSection> get navigationSections => _navigationSections;

  /// Surfaces the most recent write failure (e.g. add/update student) so the UI
  /// can show a snackbar. Consume it via [consumeError].
  String? get lastError => _lastError;

  /// Returns and clears the pending error message.
  String? consumeError() {
    final error = _lastError;
    _lastError = null;
    return error;
  }

  /// Surfaces a success/info message (e.g. the new student's login email) so
  /// the UI can show a confirmation snackbar. Consume it via [consumeInfo].
  String? get lastInfo => _lastInfo;

  /// Returns and clears the pending info message.
  String? consumeInfo() {
    final info = _lastInfo;
    _lastInfo = null;
    return info;
  }

  /// Whether the WhatsApp sender (used to deliver OTPs) is currently online.
  bool get whatsAppConnected => _whatsAppConnected;

  /// Human-readable detail about the WhatsApp sender state.
  String get whatsAppMessage => _whatsAppMessage;

  /// True only when a check has completed and the sender is NOT connected, so
  /// the admin should be warned that OTP delivery will fail.
  bool get showWhatsAppAlert => _whatsAppChecked && !_whatsAppConnected;

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
    // Check the WhatsApp sender connection in the background so the dashboard
    // can warn the admin if OTP delivery is currently broken.
    unawaited(refreshWhatsAppStatus());
  }

  /// Fetches the live WhatsApp sender status from the backend. Failures are
  /// swallowed so a status hiccup never blocks the dashboard.
  Future<void> refreshWhatsAppStatus() async {
    try {
      final response = await _apiClient.getJson('/api/admin/whatsapp-status');
      final data = response['data'] as Map<String, dynamic>? ?? const {};
      _whatsAppConnected = data['connected'] == true;
      _whatsAppMessage = data['message']?.toString() ?? '';
      _whatsAppChecked = true;
      notifyListeners();
    } catch (_) {
      // Ignore: do not disrupt the dashboard if the status endpoint is down.
    }
  }

  Future<void> addStudent(StudentRecord student) async {
    _state?.students.insert(0, student);
    notifyListeners();
    try {
      final loginEmail = await _repository.createStudent(student);
      // Re-sync with the backend so the locally-inserted record is replaced by
      // the persisted row (with its real id), keeping later edits/deletes valid.
      if (_repository.isConfigured) {
        await loadState();
      }
      final email = loginEmail ?? (student.email.isNotEmpty ? student.email : null);
      if (email != null) {
        _lastInfo =
            'Student added. Portal login email: $email (password: Demo@12345)';
        notifyListeners();
      }
    } catch (error) {
      _lastError = 'Could not save student: ${_describeError(error)}';
      // Drop the optimistic insert by reloading the real backend state.
      if (_repository.isConfigured) {
        await loadState();
      } else {
        notifyListeners();
      }
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
      if (_repository.isConfigured) {
        await loadState();
      }
    } catch (error) {
      _lastError = 'Could not update student: ${_describeError(error)}';
      if (_repository.isConfigured) {
        await loadState();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> deleteStudent(String studentId) async {
    _state?.students.removeWhere((item) => item.id == studentId);
    notifyListeners();
    try {
      await _repository.deleteStudentRecord(studentId);
    } catch (error) {
      _lastError = 'Could not delete student: ${_describeError(error)}';
      if (_repository.isConfigured) {
        await loadState();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> addTeacher(TeacherRecord teacher) async {
    _state?.teachers.insert(0, teacher);
    notifyListeners();
    try {
      final loginEmail = await _repository.createTeacher(teacher);
      if (_repository.isConfigured) {
        await loadState();
      }
      final email =
          loginEmail ?? (teacher.email.isNotEmpty ? teacher.email : null);
      if (email != null) {
        _lastInfo =
            'Teacher added. Login email: $email (password: Demo@12345)';
        notifyListeners();
      }
    } catch (error) {
      _lastError = 'Could not save teacher: ${_describeError(error)}';
      if (_repository.isConfigured) {
        await loadState();
      } else {
        notifyListeners();
      }
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
      if (_repository.isConfigured) {
        await loadState();
      }
    } catch (error) {
      _lastError = 'Could not update teacher: ${_describeError(error)}';
      if (_repository.isConfigured) {
        await loadState();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    _state?.teachers.removeWhere((item) => item.id == teacherId);
    notifyListeners();
    try {
      await _repository.deleteTeacherRecord(teacherId);
      if (_repository.isConfigured) {
        await loadState();
      }
    } catch (error) {
      _lastError = 'Could not delete teacher: ${_describeError(error)}';
      if (_repository.isConfigured) {
        await loadState();
      } else {
        notifyListeners();
      }
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

  /// Produces a concise, user-facing message from a thrown error.
  String _describeError(Object error) {
    final message = error is StateError ? error.message : error.toString();
    return message.replaceFirst(RegExp(r'^Exception:\s*'), '');
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
