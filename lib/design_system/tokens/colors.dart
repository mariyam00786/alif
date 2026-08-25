import 'package:flutter/material.dart';

/// Color palette tokens for the design system.
///
/// Values are aligned with the main design system (design-system/lib/src/theme/colors.dart)
/// and the TypeScript color tokens (design-system/colors.ts).
class ColorPalette {
  ColorPalette._();

  // Primary colors
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);

  // Secondary colors (Sage green)
  static const Color secondary = Color(0xFFA7C4A0);

  // White / Black
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Neutral scale (Material grey)
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral900 = Color(0xFF212121);

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Rating colors (4-level scale)
  static const Color ratingExcellent = Color(0xFF2E7D32);
  static const Color ratingSatisfactory = Color(0xFFFFC107);
  static const Color ratingNeedsImprovement = Color(0xFFFF9800);
  static const Color ratingNotDone = Color(0xFF9E9E9E);
}
