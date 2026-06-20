import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'screens/auth/google_login_screen.dart';
import 'screens/dashboard/student_dashboard_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'services/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.ensureInitialized();
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
            return MediaQuery(
              data: media.copyWith(textScaler: clamped),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: _resolveHome(context, appState),
        );
      },
    );
  }

  Widget _resolveHome(BuildContext context, AppStateProvider appState) {
    if (!appState.isLoggedIn) {
      return MobileGoogleLoginScreen(
        onLoginSuccess: (role) => context.read<AppStateProvider>().login(role),
      );
    }

    if (appState.activeRole == 'parent') {
      return ParentDashboard(
        locale: appState.locale,
        onLocaleChanged: (locale) =>
            context.read<AppStateProvider>().setLocale(locale),
        onLogout: () => context.read<AppStateProvider>().logout(),
      );
    }

    if (appState.activeRole == 'teacher') {
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
    );
  }
}
