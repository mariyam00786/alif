import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/apis.dart';
import '../model/api_response.dart';

/// Mobile app API service client
///
/// Simplified version for mobile with:
/// - Authentication token management
/// - Request/response handling
/// - Error handling and retry logic
/// - Cached responses
class MobileApiService {
  static const String baseUrl = Apis.baseUrl;
  static const Duration timeout = Duration(seconds: 20);

  static String? _authToken;
  static final Map<String, dynamic> _responseCache = {};

  /// Set auth token after login
  static void setAuthToken(String token) {
    _authToken = token;
  }

  /// Get current auth token
  static String? getAuthToken() => _authToken;

  /// Clear auth token on logout
  static void clearAuthToken() {
    _authToken = null;
    _responseCache.clear();
  }

  /// Build request headers
  static Map<String, String> _buildHeaders({bool requireAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ===== AUTHENTICATION =====

  static Future<ApiResponse<Map<String, dynamic>>> requestOtp(
    String phone,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/request-otp'),
            headers: _buildHeaders(requireAuth: false),
            body: jsonEncode({'phone': phone}),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to request OTP');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> verifyOtp(
    String phone,
    String otp,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: _buildHeaders(requireAuth: false),
            body: jsonEncode({'phone': phone, 'otp': otp}),
          )
          .timeout(timeout);

      final result = _parseResponse(response);
      if (result.success && result.data != null) {
        setAuthToken(result.data!['token'] ?? '');
      }
      return result;
    } catch (e) {
      return ApiResponse.error('Failed to verify OTP');
    }
  }

  // ===== DAILY RECORDS =====

  static Future<ApiResponse<Map<String, dynamic>>> createDailyRecord({
    required String studentId,
    required String date,
    required List<Map<String, dynamic>> activities,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/daily-records'),
            headers: _buildHeaders(),
            body: jsonEncode({
              'student_id': studentId,
              'date': date,
              'activities': activities,
            }),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to create daily record');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getDailyRecord(
    String recordId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/daily-records/$recordId'),
            headers: _buildHeaders(),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch daily record');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> submitDailyRecord(
    String recordId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/daily-records/$recordId/submit'),
            headers: _buildHeaders(),
            body: jsonEncode({}),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to submit daily record');
    }
  }

  // ===== ACTIVITIES =====

  static Future<ApiResponse<Map<String, dynamic>>> getDailyStructure() async {
    try {
      final cacheKey = 'daily-structure';
      if (_responseCache.containsKey(cacheKey)) {
        return ApiResponse(success: true, data: _responseCache[cacheKey]);
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/activities/structure/daily'),
            headers: _buildHeaders(),
          )
          .timeout(timeout);

      final result = _parseResponse(response);
      if (result.success && result.data != null) {
        _responseCache[cacheKey] = result.data;
      }
      return result;
    } catch (e) {
      return ApiResponse.error('Failed to fetch daily structure');
    }
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getActivities() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/activities'), headers: _buildHeaders())
          .timeout(timeout);

      final result = _parseResponse(response);
      if (result.success && result.data is List) {
        return ApiResponse(
          success: true,
          data: List<Map<String, dynamic>>.from(result.data as List),
        );
      }
      return ApiResponse.error('Failed to parse activities');
    } catch (e) {
      return ApiResponse.error('Failed to fetch activities');
    }
  }

  /// Persist a single activity log (one marked activity for a given day).
  ///
  /// Upserts on (student, activity, date) so re-submitting the same day
  /// updates the existing record rather than creating duplicates.
  static Future<ApiResponse<Map<String, dynamic>>> submitActivityLog({
    required String studentId,
    required String activityId,
    required String logDate,
    required String ratingId,
    int? quantity,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'studentId': studentId,
        'activityId': activityId,
        'logDate': logDate,
        'ratingId': ratingId,
      };
      if (quantity != null) body['quantity'] = quantity;
      if (notes != null) body['notes'] = notes;

      final response = await http
          .post(
            Uri.parse('$baseUrl/activity-logs'),
            headers: _buildHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to save activity log');
    }
  }

  /// Real dashboard summary for the authenticated student (today completion,
  /// points, streak, batch rank).
  static Future<ApiResponse<Map<String, dynamic>>> getHomeSummary() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/students/me/home-summary'),
            headers: _buildHeaders(),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch home summary');
    }
  }

  /// Real batch leaderboard for the authenticated student across four periods
  /// (daily / weekly / monthly / all_time).
  static Future<ApiResponse<Map<String, dynamic>>> getMyLeaderboard() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/students/me/leaderboard'),
            headers: _buildHeaders(),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch leaderboard');
    }
  }

  /// Real badge collection for the authenticated student (all active badges
  /// with an `earned` flag).
  static Future<ApiResponse<Map<String, dynamic>>> getBadges() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/students/me/badges'),
            headers: _buildHeaders(),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch badges');
    }
  }

  /// Update the authenticated student's own profile (name + phone).
  static Future<ApiResponse<Map<String, dynamic>>> updateMyProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;

      final response = await http
          .put(
            Uri.parse('$baseUrl/students/me'),
            headers: _buildHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to update profile');
    }
  }

  // ===== PROGRESS =====

  static Future<ApiResponse<Map<String, dynamic>>> getDailyProgress(
    String studentId,
    String date,
  ) async {
    try {
      final params = {'date': date};
      final uri = Uri.parse(
        '$baseUrl/students/$studentId/progress/daily',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch daily progress');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getWeeklyProgress(
    String studentId,
    String weekStart,
  ) async {
    try {
      final params = {'week_start': weekStart};
      final uri = Uri.parse(
        '$baseUrl/students/$studentId/progress/weekly',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch weekly progress');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getMonthlyProgress(
    String studentId,
    String monthStart,
  ) async {
    try {
      final params = {'month_start': monthStart};
      final uri = Uri.parse(
        '$baseUrl/students/$studentId/progress/monthly',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch monthly progress');
    }
  }

  // ===== LEADERBOARD =====

  static Future<ApiResponse<List<Map<String, dynamic>>>> getLeaderboard(
    String batchId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/batches/$batchId/leaderboard'),
            headers: _buildHeaders(),
          )
          .timeout(timeout);

      final result = _parseResponse(response);
      if (result.success && result.data is List) {
        return ApiResponse(
          success: true,
          data: List<Map<String, dynamic>>.from(result.data as List),
        );
      }
      return ApiResponse.error('Failed to parse leaderboard');
    } catch (e) {
      return ApiResponse.error('Failed to fetch leaderboard');
    }
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getWeeklyLeaderboard(
    String batchId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/batches/$batchId/leaderboard/weekly'),
            headers: _buildHeaders(),
          )
          .timeout(timeout);

      final result = _parseResponse(response);
      if (result.success && result.data is List) {
        return ApiResponse(
          success: true,
          data: List<Map<String, dynamic>>.from(result.data as List),
        );
      }
      return ApiResponse.error('Failed to parse leaderboard');
    } catch (e) {
      return ApiResponse.error('Failed to fetch leaderboard');
    }
  }

  // ===== NOTIFICATIONS =====

  /// Fetch announcements relevant to the signed-in parent's children.
  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getParentNotifications() async {
    try {
      final response = await http
          .get(Uri.parse(Apis.parentNotifications()), headers: _buildHeaders())
          .timeout(timeout);

      final result = _parseResponse(response);
      if (result.success && result.data is List) {
        return ApiResponse(
          success: true,
          data: List<Map<String, dynamic>>.from(result.data as List),
        );
      }
      return ApiResponse.error('Failed to parse notifications');
    } catch (e) {
      return ApiResponse.error('Failed to fetch notifications');
    }
  }

  // ===== RESPONSE PARSING =====

  static ApiResponse<Map<String, dynamic>> _parseResponse(
    http.Response response,
  ) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: json['success'] ?? true,
          data: json['data'] ?? json,
          message: json['message'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: json['message'] ?? 'API Error',
          data: json,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response');
    }
  }
}
