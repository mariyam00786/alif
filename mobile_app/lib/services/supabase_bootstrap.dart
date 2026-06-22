import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static bool _initialized = false;

  static String get _url => _sanitize(_supabaseUrl);
  static String get _key => _sanitize(_supabaseAnonKey);

  static bool get isConfigured => _url.isNotEmpty && _key.isNotEmpty;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> ensureInitialized() async {
    if (_initialized || !isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: _url,
      publishableKey: _key,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  /// Removes surrounding whitespace and any non-printable/non-ASCII characters
  /// (e.g. a smart dash, curly quote, or zero-width space accidentally pasted
  /// into a `--dart-define`). Such characters are invalid in HTTP header values
  /// and cause a "String contains non ISO-8859-1 code point" error when the
  /// anon key is sent as the `apikey`/`Authorization` header during sign-in.
  static String _sanitize(String value) =>
      value.trim().replaceAll(RegExp(r'[^\x21-\x7E]'), '');

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
}
