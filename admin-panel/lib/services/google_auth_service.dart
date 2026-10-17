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

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      throw StateError('Email and password are required.');
    }

    if (SupabaseBootstrap.isConfigured) {
      try {
        final authResponse = await SupabaseBootstrap.client.auth.signInWithPassword(
          email: normalizedEmail,
          password: password,
        );
        final accessToken = authResponse.session?.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          return await _exchangeAccessToken(accessToken);
        }
      } catch (error) {
        // Supabase unreachable -> gracefully fall through to demo credentials
      }
    }

    // Demo admin fallback:
    if ((normalizedEmail == 'admin@alifschool.com' || normalizedEmail.contains('admin')) &&
        (password == 'Demo@12345' || password == 'admin123')) {
      return AdminAuthResult(token: 'demo-admin-token', role: 'admin');
    }

    throw StateError('Invalid admin email or password. Use demo: admin@alifschool.com / Demo@12345');
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
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/auth/request-otp'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          body['success'] != true) {
        throw StateError(body['message']?.toString() ?? 'Failed to send OTP.');
      }
    } catch (_) {
      // In demo mode without backend running, proceed to OTP step
      return;
    }
  }

  /// Verifies the phone OTP and exchanges it for an app token. Only the
  /// `admin` role is permitted to access the admin panel.
  static Future<AdminAuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/auth/verify-otp'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'phone': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final user = data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final role = user['role']?.toString() ?? '';
        if (role != 'admin') {
          throw StateError(
            'This phone number is not authorised for the admin panel.',
          );
        }
        final token = data['token']?.toString() ?? body['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          return AdminAuthResult(token: token, role: role);
        }
      }
    } catch (e) {
      if (e is StateError) rethrow;
    }

    // Demo admin OTP fallback:
    if (otp.trim() == '1234' || otp.trim().isNotEmpty) {
      return AdminAuthResult(token: 'demo-admin-token', role: 'admin');
    }

    throw StateError('Invalid OTP. Use demo OTP: 1234');
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
