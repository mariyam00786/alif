import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'textstyles.dart';
import 'dimensions.dart';

// Re-export the shared app state so screens importing the theme also receive
// the [AppLocale] enum and the Provider-backed BuildContext helpers.
export '../provider/app_state_provider.dart';

/// Centralized theme provider
///
/// Provides:
/// - Consistent color scheme across app
/// - Typography styles
/// - Component styling
/// - Dark/Light theme support (future)
/// - RTL/LTR text direction support
/// - Locale management (English/Malayalam)
class AlifTheme {
  // Theme colors
  static const Color primaryDark = ColorPalette.primaryDark;
  static const Color primaryLight = ColorPalette.primaryLight;
  static const Color secondary = ColorPalette.secondary;

  // Text colors
  static const Color textPrimary = ColorPalette.textPrimary;
  static const Color textSecondary = ColorPalette.textSecondary;
  static const Color textTertiary = ColorPalette.textTertiary;

  // Background colors
  static const Color backgroundLight = ColorPalette.white;
  static const Color backgroundMuted = ColorPalette.neutral50;
  static const Color backgroundDark = ColorPalette.neutral900;

  // Neutral colors
  static const Color neutral100 = ColorPalette.neutral100;
  static const Color neutral200 = ColorPalette.neutral200;
  static const Color neutral300 = ColorPalette.neutral300;
  static const Color neutral400 = ColorPalette.neutral400;
  static const Color neutral500 = ColorPalette.neutral500;
  static const Color neutral600 = ColorPalette.neutral600;

  // Rating colors
  static const Color ratingExcellent = ColorPalette.ratingExcellent;
  static const Color ratingSatisfactory = ColorPalette.ratingSatisfactory;
  static const Color ratingNeedsImprovement =
      ColorPalette.ratingNeedsImprovement;
  static const Color ratingNotDone = ColorPalette.ratingNotDone;

  // Border radius
  static const double radiusSmall = 6;
  static const double radiusMedium = 10;
  static const double radiusLarge = 14;
  static const double radiusXLarge = 18;
  static const double radiusFull = 28;

  /// Get ThemeData for Material Design
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: ColorPalette.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: TypographySystem.textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.xl.toDouble(),
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: BorderSide(color: primaryDark.withValues(alpha: 0.3)),
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.xl.toDouble(),
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.md.toDouble(),
            vertical: SpacingScale.sm.toDouble(),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(
          horizontal: SpacingScale.md.toDouble(),
          vertical: SpacingScale.md.toDouble() + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: ratingNeedsImprovement),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: ratingNeedsImprovement, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: neutral400, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
          side: BorderSide(color: neutral200.withValues(alpha: 0.7), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: SpacingScale.lg.toDouble(),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryDark,
        secondary: secondary,
        surface: backgroundLight,
        error: ratingNeedsImprovement,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
    );
  }

  /// Get ThemeData for dark theme (future implementation)
  static ThemeData getDarkTheme() {
    // TODO: Implement dark theme
    return getLightTheme();
  }
}

/// Theme configuration holder
class ThemeConfig {
  // Spacing constants
  static double get spacingXS => SpacingScale.xs.toDouble();
  static double get spacingSM => SpacingScale.sm.toDouble();
  static double get spacingMD => SpacingScale.md.toDouble();
  static double get spacingLG => SpacingScale.lg.toDouble();
  static double get spacingXL => SpacingScale.xl.toDouble();
  static double get spacingXXL => SpacingScale.xxl.toDouble();

  // Border radius constants
  static BorderRadius get radiusSmall =>
      BorderRadius.circular(AlifTheme.radiusSmall);
  static BorderRadius get radiusMedium =>
      BorderRadius.circular(AlifTheme.radiusMedium);
  static BorderRadius get radiusLarge =>
      BorderRadius.circular(AlifTheme.radiusLarge);
  static BorderRadius get radiusXLarge =>
      BorderRadius.circular(AlifTheme.radiusXLarge);
  static BorderRadius get radiusFull =>
      BorderRadius.circular(AlifTheme.radiusFull);

  // Common shadows — softer, layered for premium feel
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}
