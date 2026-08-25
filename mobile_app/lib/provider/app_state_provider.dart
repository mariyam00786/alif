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

  /// The portal currently being shown. Usually equals [_activeRole], but a
  /// dual student/parent account can flip this to switch views without signing
  /// out (e.g. a student who is also linked to children opening the parent
  /// board, then returning to their own student board).
  String? _activeView;

  /// Whether the signed-in account is also linked to one or more children, as
  /// reported by the backend at sign-in. Drives the in-portal switch option.
  bool _hasParentAccess = false;

  // ===== Getters =====
  AppLocale get locale => _locale;
  bool get isDarkMode => _isDarkMode;
  bool get isMalayalam => _locale == AppLocale.ml;
  // Both supported locales (English and Malayalam) are left-to-right scripts.
  TextDirection get textDirection => TextDirection.ltr;
  bool get isLoggedIn => _isLoggedIn;
  String? get activeRole => _activeRole;
  String? get currentStudentId => _currentStudentId;

  /// The portal currently displayed (defaults to the authenticated role).
  String? get activeView => _activeView ?? _activeRole;

  /// Whether this account can open the parent view (a student/parent account).
  bool get hasParentAccess => _hasParentAccess;

  /// Whether a "switch to parent" action should be offered in the student view.
  /// The parent board always lives inside the student portal as a switch, so it
  /// is offered to any student account (and any account linked to children).
  bool get canSwitchToParent =>
      activeView != 'parent' && (_activeRole == 'student' || _hasParentAccess);

  /// Whether a "switch to student" action should be offered in the parent view.
  /// Only student accounts have their own student board to return to.
  bool get canSwitchToStudent =>
      _activeRole == 'student' && activeView == 'parent';

  /// Whether a parent still needs to pick which child to view.
  bool get needsStudentSelection =>
      activeView == 'parent' && _currentStudentId == null;

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
  void login(String role, {bool hasParentAccess = false}) {
    _isLoggedIn = true;
    _activeRole = role;
    _activeView = role;
    _hasParentAccess = hasParentAccess;
    _currentStudentId = role == 'student' ? 'self' : null;
    notifyListeners();
  }

  /// Switches the current display to the parent board (dual account). The own
  /// student board is exited and the parent must pick a child to view.
  void switchToParentView() {
    if (activeView == 'parent') return;
    _activeView = 'parent';
    _currentStudentId = null;
    notifyListeners();
  }

  /// Returns a dual account from the parent board back to its own student board.
  void switchToStudentView() {
    if (_activeRole != 'student') return;
    _activeView = 'student';
    _currentStudentId = 'self';
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
    _activeView = null;
    _hasParentAccess = false;
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
