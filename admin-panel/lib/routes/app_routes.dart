import 'package:flutter/material.dart';

import '../app.dart';

/// Named route definitions for the admin panel.
///
/// The admin app is primarily section-driven through [AdminProvider] inside a
/// single shell, so the root route hosts the full application shell.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const AlifAdminApp(),
          settings: settings,
        );
    }
  }
}
