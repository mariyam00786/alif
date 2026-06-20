import 'package:flutter/material.dart';

/// Unified error and feedback handler
/// 
/// Features:
/// - SnackBar notifications (success, error, info, warning)
/// - Dialog alerts and confirmations
/// - Toast-like notifications
/// - Error logging
/// - Bilingual support
class FeedbackHandler {
  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message,
      SnackBarType.success,
      duration: duration,
    );
  }

  /// Show error message
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context,
      message,
      SnackBarType.error,
      duration: duration,
    );
  }

  /// Show info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message,
      SnackBarType.info,
      duration: duration,
    );
  }

  /// Show warning message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message,
      SnackBarType.warning,
      duration: duration,
    );
  }

  /// Internal snackbar handler
  static void _showSnackBar(
    BuildContext context,
    String message,
    SnackBarType type, {
    required Duration duration,
  }) {
    final colors = _getTypeColors(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(colors.icon, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String okText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(okText),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  /// Log error
  static void logError(String tag, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('[$tag] Error: $error');
    if (stackTrace != null) {
      debugPrint('[$tag] StackTrace: $stackTrace');
    }
  }
}

/// Snackbar type enum
enum SnackBarType { success, error, info, warning }

/// Type colors configuration
class _TypeColors {
  final IconData icon;
  final Color backgroundColor;

  _TypeColors({
    required this.icon,
    required this.backgroundColor,
  });
}

/// Get colors for snackbar type
_TypeColors _getTypeColors(SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return _TypeColors(
        icon: Icons.check_circle,
        backgroundColor: Color(0xFF2E7D32),
      );
    case SnackBarType.error:
      return _TypeColors(
        icon: Icons.error,
        backgroundColor: Color(0xFFD32F2F),
      );
    case SnackBarType.warning:
      return _TypeColors(
        icon: Icons.warning,
        backgroundColor: Color(0xFFFFA000),
      );
    case SnackBarType.info:
      return _TypeColors(
        icon: Icons.info,
        backgroundColor: Color(0xFF1976D2),
      );
  }
}

/// Extension for easier error handling
extension ErrorHandling on BuildContext {
  void showSuccess(String message) =>
      FeedbackHandler.showSuccess(this, message);

  void showError(String message) => FeedbackHandler.showError(this, message);

  void showInfo(String message) => FeedbackHandler.showInfo(this, message);

  void showWarning(String message) =>
      FeedbackHandler.showWarning(this, message);

  Future<bool> showConfirm({
    required String title,
    required String message,
  }) =>
      FeedbackHandler.showConfirmation(
        this,
        title: title,
        message: message,
      );

  void showLoading([String message = 'Loading...']) =>
      FeedbackHandler.showLoadingDialog(this, message: message);

  void hideLoading() => FeedbackHandler.hideLoadingDialog(this);
}

/// Form validation error handler
class FormValidator {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone is required';
    }
    if (!value.startsWith('+')) {
      return 'Phone must start with +';
    }
    if (value.length < 12) {
      return 'Phone must be at least 12 characters';
    }
    return null;
  }

  static String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMinLength(String? value, int min, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? validateMaxLength(String? value, int max, String fieldName) {
    if (value == null) return null;
    if (value.length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }
}

/// API error handler
class ApiErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error is Map) {
      if (error.containsKey('message')) {
        return error['message'].toString();
      }
      if (error.containsKey('error')) {
        return error['error'].toString();
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static bool isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout');
  }

  static bool isAuthError(int statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  static bool isServerError(int statusCode) {
    return statusCode >= 500;
  }

  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }
}

/// Exception class for app-wide use
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Network exception
class NetworkException extends AppException {
  NetworkException({
    super.message = 'Network error occurred',
    super.originalError,
  }) : super(code: 'NETWORK_ERROR');
}

/// Server exception
class ServerException extends AppException {
  ServerException({
    super.message = 'Server error occurred',
    super.originalError,
  }) : super(code: 'SERVER_ERROR');
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.originalError,
  }) : super(code: 'VALIDATION_ERROR');
}
