import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/admin_shell.dart';
import 'components/admin_top_actions.dart';
import 'components/whatsapp_alert_banner.dart';
import 'constants/app_theme.dart';
import 'model/app_models.dart';
import 'provider/admin_provider.dart';
import 'screens/activity_configuration_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_otp_login_screen.dart';
import 'screens/badge_management_screen.dart';
import 'screens/batch_management_screen.dart';
import 'screens/notification_management_screen.dart';
import 'screens/rating_configuration_screen.dart';
import 'screens/reports_dashboard_screen.dart';
import 'screens/student_management_screen.dart';
import 'screens/teacher_management_screen.dart';

/// Default subject options offered when adding a teacher, so the subject
/// selector always has choices even before any teacher has been saved.
const List<String> kDefaultTeacherSubjects = [
  'Qur\'an',
  'Tajweed',
  'Hadith',
  'Fiqh',
  'Aqeedah',
  'Akhlaq (Moral Science)',
  'Arabic Language',
  'Islamic History',
  'Dua & Adhkar',
];

class AlifAdminApp extends StatelessWidget {
  const AlifAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alif School Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAlifAdminTheme(),
      home: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          final error = provider.consumeError();
          if (error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            });
          }

          final info = provider.consumeInfo();
          if (info != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(
                  content: Text(info),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 8),
                ),
              );
            });
          }

          if (!provider.isLoggedIn) {
            return AdminOtpLoginScreen(
              onLoginSuccess: provider.handleLoginSuccess,
            );
          }

          return AdminShell(
            selectedSection: provider.selectedSection,
            sections: provider.navigationSections,
            onSectionSelected: provider.selectSection,
            onSignOut: provider.handleLogout,
            notifications: _bellNotifications(provider),
            child: provider.loading || provider.state == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (provider.showWhatsAppAlert)
                        WhatsAppAlertBanner(
                          message: provider.whatsAppMessage,
                          onRetry: provider.refreshWhatsAppStatus,
                        ),
                      Expanded(child: _buildScreen(provider)),
                    ],
                  ),
          );
        },
      ),
    );
  }

  /// Builds the notification list shown in the top-bar bell from the backend
  /// campaigns already loaded by the provider, falling back to sample data when
  /// nothing has loaded yet.
  List<AdminNotification> _bellNotifications(AdminProvider provider) {
    final campaigns = provider.state?.notifications ?? const [];
    if (campaigns.isEmpty) return kAdminNotifications;
    return adminNotificationsFromCampaigns(campaigns);
  }

  Widget _buildScreen(AdminProvider provider) {
    final state = provider.state!;
    final availableClasses = {
      ...state.classes,
      ...state.students.map((student) => student.className),
      ...state.batchClasses.map((batch) => batch.className),
    }.where((value) => value.isNotEmpty).toList()..sort();
    final availableSubjects = {
      ...kDefaultTeacherSubjects,
      for (final teacher in state.teachers) ...teacher.subjects,
    }.where((value) => value.isNotEmpty).toList()..sort();

    switch (provider.selectedSection) {
      case AdminSection.dashboard:
        return AdminDashboardScreen(state: state);
      case AdminSection.students:
        return StudentManagementScreen(
          students: state.students,
          availableBatches: state.batchClasses
              .map((batch) => batch.name)
              .toList(),
          availableClasses: availableClasses,
          onAdd: provider.addStudent,
          onUpdate: provider.updateStudent,
          onDelete: provider.deleteStudent,
        );
      case AdminSection.teachers:
        return TeacherManagementScreen(
          teachers: state.teachers,
          availableSubjects: availableSubjects,
          availableBatches: state.batchClasses
              .map((batch) => batch.name)
              .toList(),
          onAdd: provider.addTeacher,
          onUpdate: provider.updateTeacher,
          onDelete: provider.deleteTeacher,
        );
      case AdminSection.batches:
        return BatchManagementScreen(
          batches: state.batchClasses,
          availableTeachers: state.teachers
              .map((teacher) => teacher.name)
              .toList(),
          availableClasses: availableClasses,
          onAdd: provider.addBatch,
          onUpdate: provider.updateBatch,
          onDelete: provider.deleteBatch,
        );
      case AdminSection.activities:
        return ActivityConfigurationScreen(
          activities: state.activities,
          onAdd: provider.addActivity,
          onUpdate: provider.updateActivity,
          onDelete: provider.deleteActivity,
        );
      case AdminSection.rating:
        return RatingConfigurationScreen(
          ratingRules: state.ratingRules,
          onAdd: provider.addRatingRule,
          onUpdate: provider.updateRatingRule,
          onDelete: provider.deleteRatingRule,
        );
      case AdminSection.reports:
        return ReportsDashboardScreen(state: state);
      case AdminSection.notifications:
        return NotificationManagementScreen(
          campaigns: state.notifications,
          batches: state.batchClasses.map((batch) => batch.name).toList(),
          classes: availableClasses,
          onAdd: provider.addNotification,
          onUpdate: provider.updateNotification,
          onDelete: provider.deleteNotification,
        );
      case AdminSection.badges:
        return BadgeManagementScreen(
          badges: state.badges,
          onAdd: provider.addBadge,
          onUpdate: provider.updateBadge,
          onDelete: provider.deleteBadge,
        );
    }
  }
}
