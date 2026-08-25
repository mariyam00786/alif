/// Firebase is not currently wired into this app (auth and data use
/// Supabase). This stub preserves the bootstrap API surface so callers can
/// safely invoke it, while avoiding a dependency on `firebase_core`.
///
/// When Firebase is adopted, add `firebase_core` to `pubspec.yaml` and
/// restore the real initialization here.
class FirebaseBootstrap {
  static bool get isConfigured => false;

  static Future<void> ensureInitialized() async {
    // No-op until Firebase is configured.
  }
}
