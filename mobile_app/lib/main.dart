import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/student_dashboard_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'services/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase, but never let it block the first frame. If the call
  // hangs (e.g. a web auth lock held by another tab) or throws, we still render
  // the UI so the user does not get a permanent blank page.
  try {
    await SupabaseBootstrap.ensureInitialized().timeout(
      const Duration(seconds: 8),
    );
  } catch (error, stackTrace) {
    debugPrint('Supabase initialisation failed or timed out: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppStateProvider())],
      child: const AlifMobileApp(),
    ),
  );
}

class AlifMobileApp extends StatelessWidget {
  const AlifMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        return MaterialApp(
          title: 'Alif Student Portal',
          debugShowCheckedModeBanner: false,
          theme: AlifTheme.getLightTheme(),
          darkTheme: AlifTheme.getDarkTheme(),
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          supportedLocales: const [Locale('en', 'US'), Locale('ml', 'IN')],
          builder: (context, child) {
            // Clamp the system text scale so very large accessibility font
            // settings cannot overflow the compact phone layouts, while still
            // honouring moderate user scaling for readability.
            final media = MediaQuery.of(context);
            final clamped = media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.30,
            );
            // Keep the app at a single phone-sized column and centre it, so on
            // tablets / desktop / web it still reads as one mobile screen
            // instead of stretching edge to edge.
            return MediaQuery(
              data: media.copyWith(textScaler: clamped),
              child: ColoredBox(
                color: const Color(0xFFDDE3DD),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
          home: _resolveHome(context, appState),
        );
      },
    );
  }

  Widget _resolveHome(BuildContext context, AppStateProvider appState) {
    if (!appState.isLoggedIn) {
      return MobileLoginScreen(
        onLoginSuccess: (role, {bool hasParentAccess = false}) => context
            .read<AppStateProvider>()
            .login(role, hasParentAccess: hasParentAccess),
      );
    }

    final view = appState.activeView;

    if (view == 'parent') {
      return ParentDashboard(
        locale: appState.locale,
        onLocaleChanged: (locale) =>
            context.read<AppStateProvider>().setLocale(locale),
        onLogout: () => context.read<AppStateProvider>().logout(),
        onSwitchToStudent: appState.canSwitchToStudent
            ? () => context.read<AppStateProvider>().switchToStudentView()
            : null,
      );
    }

    if (view == 'teacher') {
      return TeacherDashboard(
        locale: appState.locale,
        onLocaleChanged: (locale) =>
            context.read<AppStateProvider>().setLocale(locale),
        onLogout: () => context.read<AppStateProvider>().logout(),
      );
    }

    return MobileStudentDashboard(
      locale: appState.locale,
      onLocaleChanged: (locale) =>
          context.read<AppStateProvider>().setLocale(locale),
      onLogout: () => context.read<AppStateProvider>().logout(),
      studentId: appState.effectiveStudentId,
      studentName: 'My Progress',
      onSwitchToParent: appState.canSwitchToParent
          ? () => context.read<AppStateProvider>().switchToParentView()
          : null,
    );
  }
}
