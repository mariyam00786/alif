import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

class AdminAuthResult {
  AdminAuthResult({required this.token, required this.role});

  final String token;
  final String role;
}

class AdminAuthService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static Future<AdminAuthResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await SupabaseBootstrap.ensureInitialized();

    if (!SupabaseBootstrap.isConfigured) {
      throw StateError(
        'Supabase email sign-in is not configured. Add the Supabase dart-defines before running the app.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      throw StateError('Email and password are required.');
    }

    final authResponse = await SupabaseBootstrap.client.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );

    final accessToken = authResponse.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError(
        'Sign-in succeeded but Supabase did not return an access token.',
      );
    }

    return _exchangeAccessToken(accessToken);
  }

  static Future<void> signInWithGoogle() async {
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

  /// Requests a phone OTP (delivered via WhatsApp) for admin sign-in.
  static Future<void> requestOtp(String phone) async {
    final response = await http
        .post(
          Uri.parse('$_apiBaseUrl/auth/request-otp'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw StateError(body['message']?.toString() ?? 'Failed to send OTP.');
    }
  }

  /// Verifies the phone OTP and exchanges it for an app token. Only the
  /// `admin` role is permitted to access the admin panel.
  static Future<AdminAuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_apiBaseUrl/auth/verify-otp'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'phone': phone, 'otp': otp}),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw StateError(
        body['message']?.toString() ?? 'OTP verification failed.',
      );
    }

    final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final user = data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final role = user['role']?.toString() ?? '';
    if (role != 'admin') {
      throw StateError(
        'This phone number is not authorised for the admin panel.',
      );
    }

    final token = data['token']?.toString() ?? body['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw StateError(
        'Sign-in succeeded but the backend did not return an app token.',
      );
    }

    return AdminAuthResult(token: token, role: role);
  }

  static Future<AdminAuthResult?> restoreSession() async {
    await SupabaseBootstrap.ensureInitialized();

    if (!SupabaseBootstrap.isConfigured) {
      throw StateError(
        'Supabase admin sign-in is not configured. Add the Supabase dart-defines before running the app.',
      );
    }

    final accessToken =
        SupabaseBootstrap.client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    return _exchangeAccessToken(accessToken);
  }

  static Future<AdminAuthResult> _exchangeAccessToken(
    String accessToken,
  ) async {
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
      throw StateError(body['message']?.toString() ?? 'Google sign-in failed.');
    }

    final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final user = data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final role = user['role']?.toString() ?? '';
    if (role != 'admin') {
      await signOut();
      throw StateError(
        'This Google account is not assigned to the admin panel.',
      );
    }

    final token = data['token']?.toString() ?? body['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw StateError(
        'Sign-in succeeded but the backend did not return an app token.',
      );
    }

    return AdminAuthResult(token: token, role: role);
  }

  static Future<void> signOut() async {
    await SupabaseBootstrap.ensureInitialized();
    if (!SupabaseBootstrap.isConfigured) {
      return;
    }
    await SupabaseBootstrap.client.auth.signOut();
  }
}
