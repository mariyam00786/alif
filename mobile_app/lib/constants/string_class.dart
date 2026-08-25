/// App-wide string constants (storage keys, roles, common messages).
class StringClass {
  StringClass._();

  // Storage / preference keys
  static const String token = 'auth_token';
  static const String userId = 'user_id';

  // Roles
  static const String roleStudent = 'student';
  static const String roleParent = 'parent';

  // Common messages
  static const String noInternet = 'No Internet Connection';
  static const String serverError = 'Something went wrong';
  static const String sessionExpired = 'Session Expired, Please Login Again';
}
