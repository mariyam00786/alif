import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';
import 'supabase_bootstrap.dart';

class MobileGoogleAuthResult {
  const MobileGoogleAuthResult({required this.token, required this.role});

  final String token;
  final String role;
}

class MobileGoogleAuthService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // ===== Teacher portal (demo username + password) =====
  //
  // The teacher portal uses simple username/password credentials (FRD §4.3,
  // no OTP). There is no teacher-facing auth backend yet, so this runs in
  // demo mode against the credentials below. Swap this for a backend call
  // (POST /api/auth/teacher-signin) once teacher accounts are provisioned.
  static const String _demoTeacherUsername = 'teacher';
  static const String _demoTeacherPassword = 'teacher123';

  // ===== Student & Parent demo credentials =====
  static const String _demoStudentEmail = 'student@alifschool.com';
  static const String _demoStudentPassword = 'student123';
  static const String _demoParentEmail = 'parent@alifschool.com';
  static const String _demoParentPassword = 'parent123';

  /// Display info for a demo (non-Supabase) session, when set.
  static MobilePortalUser? _demoUser;

  /// Signs a teacher in.
  ///
  /// When Supabase is configured and an email-style username is supplied, this
  /// performs a real email + password sign-in and exchanges the session for a
  /// teacher-scoped backend token (enabling live data). Otherwise it falls
  /// back to the offline demo credentials so the portal still works in preview.
  static Future<MobileGoogleAuthResult> signInTeacher({
    required String username,
    required String password,
  }) async {
    await SupabaseBootstrap.ensureInitialized();

    final id = username.trim();
    final looksLikeEmail = id.contains('@');

    if (SupabaseBootstrap.isConfigured && looksLikeEmail) {
      final AuthResponse response;
      try {
        response = await SupabaseBootstrap.client.auth.signInWithPassword(
          email: id.toLowerCase(),
          password: password,
        );
      } on AuthException catch (error) {
        throw StateError(error.message);
      }
      final accessToken = response.session?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw StateError('Login failed. Please check your username and password.');
      }
      _demoUser = null;
      return _exchangeAccessToken(
        accessToken,
        allowedRoles: const {'teacher'},
      );
    }

    // Offline demo fallback.
    if (id.toLowerCase() != _demoTeacherUsername || password != _demoTeacherPassword) {
      throw StateError('Invalid username or password.');
    }
    _demoUser = const MobilePortalUser(
      name: 'Ustad Yusuf',
      email: 'teacher@alifschool.com',
    );
    const result = MobileGoogleAuthResult(
      token: 'demo-teacher',
      role: 'teacher',
    );
    MobileApiService.setAuthToken(result.token);
    return result;
  }

  static Future<void> signIn() async {
    await SupabaseBootstrap.ensureInitialized();

    if (!SupabaseBootstrap.isConfigured) {
      throw StateError(
        'Supabase Google sign-in is not configured. Add the Supabase dart-defines before running the app.',
      );
    }

    await SupabaseBootstrap.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Uri.base.toString(),
    );
  }

  /// Signs in with an email and password using Supabase Auth, then exchanges
  /// the resulting session for the backend app token (JWT) and role.
  /// Falls back to offline demo credentials when Supabase is not configured.
  static Future<MobileGoogleAuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await SupabaseBootstrap.ensureInitialized();

    if (!SupabaseBootstrap.isConfigured) {
      // Offline demo fallback for student/parent.
      final e = email.trim().toLowerCase();
      if (e == _demoStudentEmail && password == _demoStudentPassword) {
        _demoUser = const MobilePortalUser(
          name: 'Ahmad Hassan',
          email: 'student@alifschool.com',
        );
        const result = MobileGoogleAuthResult(
          token: 'demo-student',
          role: 'student',
        );
        MobileApiService.setAuthToken(result.token);
        return result;
      }
      if (e == _demoParentEmail && password == _demoParentPassword) {
        _demoUser = const MobilePortalUser(
          name: 'Fatima Hassan',
          email: 'parent@alifschool.com',
        );
        const result = MobileGoogleAuthResult(
          token: 'demo-parent',
          role: 'parent',
        );
        MobileApiService.setAuthToken(result.token);
        return result;
      }
      throw StateError('Invalid email or password.');
    }

    final AuthResponse response;
    try {
      response = await SupabaseBootstrap.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw StateError(error.message);
    }

    final accessToken = response.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Login failed. Please check your email and password.');
    }

    return _exchangeAccessToken(accessToken);
  }

  static Future<MobileGoogleAuthResult?> restoreSession() async {
    await SupabaseBootstrap.ensureInitialized();

    // In demo / preview mode (no Supabase config) there is no session to
    // restore — return null quietly instead of surfacing a login error.
    if (!SupabaseBootstrap.isConfigured) {
      return null;
    }

    final accessToken =
        SupabaseBootstrap.client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    return _exchangeAccessToken(accessToken);
  }

  static Future<MobileGoogleAuthResult> _exchangeAccessToken(
    String accessToken, {
    Set<String> allowedRoles = const {'student', 'parent'},
  }) async {
    final response = await http
        .post(
          Uri.parse('$_apiBaseUrl/auth/supabase-signin'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'accessToken': accessToken}),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(body['message']?.toString() ?? 'Sign-in failed.');
    }

    final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final user = data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final role = user['role']?.toString() ?? '';
    if (!allowedRoles.contains(role)) {
      await signOut();
      throw StateError(
        'This account is not assigned to the ${allowedRoles.join('/')} portal.',
      );
    }

    final token = data['token']?.toString() ?? body['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw StateError(
        'Google sign-in succeeded but the backend did not return an app token.',
      );
    }

    MobileApiService.setAuthToken(token);
    return MobileGoogleAuthResult(token: token, role: role);
  }

  static Future<void> signOut() async {
    _demoUser = null;
    MobileApiService.clearAuthToken();
    if (!SupabaseBootstrap.isConfigured) return;
    await SupabaseBootstrap.client.auth.signOut();
  }

  /// Returns display info for the currently signed-in user (from Supabase),
  /// or null when no session is available (e.g. preview mode).
  static MobilePortalUser? get currentUser {
    if (_demoUser != null) return _demoUser;
    if (!SupabaseBootstrap.isConfigured) return null;
    final user = SupabaseBootstrap.client.auth.currentUser;
    if (user == null) return null;
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final name = (meta['full_name'] ?? meta['name'])?.toString();
    final avatar = (meta['avatar_url'] ?? meta['picture'])?.toString();
    return MobilePortalUser(
      name: name?.isNotEmpty == true ? name : null,
      email: user.email,
      avatarUrl: avatar?.isNotEmpty == true ? avatar : null,
    );
  }
}

class MobilePortalUser {
  const MobilePortalUser({this.name, this.email, this.avatarUrl});
  final String? name;
  final String? email;
  final String? avatarUrl;
}
