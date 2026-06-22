import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  // Private constructor
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF0F766E); // Teal
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF115E59);

  // Secondary colors
  static const Color secondary = Color(0xFFA7C4A0); // Sage green
  static const Color secondaryLight = Color(0xFFC5DAC0);
  static const Color secondaryDark = Color(0xFF8FB088);

  // Semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF1976D2);

  // Rating scale colors (for activity ratings 1-5)
  static const Color ratePoor = Color(0xFFD32F2F); // Red
  static const Color rateFair = Color(0xFFF57C00); // Orange
  static const Color rateGood = Color(0xFFFDD835); // Yellow
  static const Color rateVeryGood = Color(0xFFAFB42B); // Lime
  static const Color rateExcellent = Color(0xFF2E7D32); // Green

  // Neutral colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color grey900 = Color(0xFF212121);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey50 = Color(0xFFFAFAFA);

  // Background colors
  static const Color background = Color(0xFFFAF9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F4F1);

  // Overlay colors
  static const Color overlay = Color(0x1A000000);
  static const Color overlayLight = Color(0x0D000000);

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1F2937);

  /// Get rating color based on rating value (1-5)
  static Color getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return ratePoor;
      case 2:
        return rateFair;
      case 3:
        return rateGood;
      case 4:
        return rateVeryGood;
      case 5:
        return rateExcellent;
      default:
        return grey400;
    }
  }

  /// Get rating label based on rating value (1-5)
  static String getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Not Rated';
    }
  }
}
