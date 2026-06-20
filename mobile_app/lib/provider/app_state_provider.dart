import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/google_auth_service.dart';

/// Supported app locales for bilingual (English / Malayalam) support.
enum AppLocale {
  en, // English
  ml, // Malayalam
}

/// Central application state provider.
///
/// Replaces the previous `setState` + `InheritedWidget` approach with a single
/// [ChangeNotifier] following the project's Provider-based MVVM architecture.
///
/// Holds:
/// - Locale & theme preferences
/// - Authentication / session state (role, selected student)
class AppStateProvider extends ChangeNotifier {
  AppLocale _locale = AppLocale.en;
  bool _isDarkMode = false;
  bool _isLoggedIn = false;
  String? _activeRole;
  String? _currentStudentId;

  // ===== Getters =====
  AppLocale get locale => _locale;
  bool get isDarkMode => _isDarkMode;
  bool get isMalayalam => _locale == AppLocale.ml;
  TextDirection get textDirection =>
      isMalayalam ? TextDirection.rtl : TextDirection.ltr;
  bool get isLoggedIn => _isLoggedIn;
  String? get activeRole => _activeRole;
  String? get currentStudentId => _currentStudentId;

  /// Whether a parent still needs to pick which child to view.
  bool get needsStudentSelection =>
      _activeRole == 'parent' && _currentStudentId == null;

  /// The student id currently being viewed (defaults to `self`).
  String get effectiveStudentId => _currentStudentId ?? 'self';

  // ===== Locale & theme =====
  void setLocale(AppLocale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    _locale = isMalayalam ? AppLocale.en : AppLocale.ml;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }

  // ===== Session =====
  void login(String role) {
    _isLoggedIn = true;
    _activeRole = role;
    _currentStudentId = role == 'student' ? 'self' : null;
    notifyListeners();
  }

  void selectStudent(String studentId) {
    _currentStudentId = studentId;
    notifyListeners();
  }

  Future<void> logout() async {
    await MobileGoogleAuthService.signOut();
    _isLoggedIn = false;
    _activeRole = null;
    _currentStudentId = null;
    notifyListeners();
  }
}

/// Convenience [BuildContext] helpers backed by [AppStateProvider].
///
/// These mirror the old `ThemeExtension` API so existing screens that use
/// `context.isMalayalam` keep working, now driven by Provider.
extension AppStateContext on BuildContext {
  /// Read the provider without subscribing to changes (for actions).
  AppStateProvider get appState => read<AppStateProvider>();

  /// Subscribe to locale changes.
  bool get isMalayalam => watch<AppStateProvider>().isMalayalam;

  /// Text direction derived from the current locale.
  TextDirection get textDirection => watch<AppStateProvider>().textDirection;

  /// Subscribe to dark-mode changes.
  bool get isDarkMode => watch<AppStateProvider>().isDarkMode;
}
