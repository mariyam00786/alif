import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  // Private constructor
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF2E7D32); // Green
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF1B5E20);

  // Secondary colors
  static const Color secondary = Color(0xFFFFA000); // Gold
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57F17);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
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
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Overlay colors
  static const Color overlay = Color(0x1A000000);
  static const Color overlayLight = Color(0x0D000000);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

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
