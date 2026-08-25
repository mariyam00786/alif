import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'provider/admin_provider.dart';
import 'services/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep first render resilient on web refreshes. If Supabase init hangs or
  // fails (network/cached tab lock/invalid env), the app still boots.
  try {
    await SupabaseBootstrap.ensureInitialized().timeout(
      const Duration(seconds: 8),
    );
  } catch (error, stackTrace) {
    debugPrint('Supabase initialization failed or timed out: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AdminProvider())],
      child: const AlifAdminApp(),
    ),
  );
}
