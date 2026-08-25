/// Centralised user-facing strings and storage keys for the admin panel.
class StringClass {
  StringClass._();

  // App
  static const String appTitle = 'Alif School Admin';

  // Storage keys
  static const String authTokenKey = 'admin_auth_token';
  static const String activeRoleKey = 'admin_active_role';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String loginFailed = 'Unable to sign in. Check your credentials.';
  static const String loadingState = 'Loading admin workspace…';
}
