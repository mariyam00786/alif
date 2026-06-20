import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/app_state_provider.dart';
import '../screens/auth/google_login_screen.dart';

/// Centralized route names and generator for the Alif mobile app.
///
/// The app shell switches its primary view reactively via [AppStateProvider],
/// but named routes are defined here for any imperative navigation.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String studentSelector = '/student-selector';
  static const String dashboard = '/dashboard';

  /// Fallback route generator.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => MobileGoogleLoginScreen(
            onLoginSuccess: (role) =>
                context.read<AppStateProvider>().login(role),
          ),
        );
    }
  }
}
