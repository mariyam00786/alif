import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';

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
  static const Color ratingNeedsImprovement = ColorPalette.ratingNeedsImprovement;
  static const Color ratingNotDone = ColorPalette.ratingNotDone;

  // Border radius
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusXLarge = 16;
  static const double radiusFull = 24;

  /// Get ThemeData for Material Design
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TypographySystem.pageTitle,
        displayMedium: TypographySystem.sectionTitle,
        headlineMedium: TypographySystem.cardTitle,
        bodyLarge: TypographySystem.bodyText,
        bodyMedium: TypographySystem.bodyText.copyWith(fontSize: 14),
        bodySmall: TypographySystem.bodyText.copyWith(fontSize: 12),
        labelLarge: TypographySystem.bodyText.copyWith(fontWeight: FontWeight.w600),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryDark,
        textTheme: ButtonTextTheme.primary,
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: SpacingScale.lg,
          vertical: SpacingScale.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.lg,
            vertical: SpacingScale.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: BorderSide(color: primaryDark),
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.lg,
            vertical: SpacingScale.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          padding: EdgeInsets.symmetric(
            horizontal: SpacingScale.md,
            vertical: SpacingScale.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(
          horizontal: SpacingScale.md,
          vertical: SpacingScale.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: ratingNeedsImprovement),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: ratingNeedsImprovement, width: 2),
        ),
        filled: true,
        fillColor: backgroundLight,
        hintStyle: TextStyle(
          color: neutral500,
          fontSize: 14,
        ),
      ),
      cardTheme: CardTheme(
        color: backgroundLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
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
        background: backgroundMuted,
        error: ratingNeedsImprovement,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
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

/// Locale enum for bilingual support
enum AppLocale {
  en,  // English
  ml,  // Malayalam
}

/// Theme provider widget
/// 
/// Usage:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return AlifThemeProvider(
///     locale: AppLocale.en,
///     child: MaterialApp(
///       theme: AlifTheme.getLightTheme(),
///       home: MyApp(),
///     ),
///   );
/// }
/// ```
class AlifThemeProvider extends InheritedWidget {
  final AppLocale locale;
  final bool isDarkMode;

  const AlifThemeProvider({
    Key? key,
    required this.locale,
    this.isDarkMode = false,
    required Widget child,
  }) : super(key: key, child: child);

  /// Get current locale from context
  static AppLocale localeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AlifThemeProvider>()?.locale ??
        AppLocale.en;
  }

  /// Check if current locale is Malayalam
  static bool isMalayalam(BuildContext context) {
    return localeOf(context) == AppLocale.ml;
  }

  /// Get text direction based on locale
  static TextDirection textDirectionOf(BuildContext context) {
    return isMalayalam(context) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Check if dark mode is enabled
  static bool isDarkModeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AlifThemeProvider>()?.isDarkMode ??
        false;
  }

  @override
  bool updateShouldNotify(AlifThemeProvider oldWidget) {
    return locale != oldWidget.locale || isDarkMode != oldWidget.isDarkMode;
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

  // Common shadows
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}

/// Extension methods for easier access to theme
extension ThemeExtension on BuildContext {
  bool get isMalayalam => AlifThemeProvider.isMalayalam(this);
  TextDirection get textDirection => AlifThemeProvider.textDirectionOf(this);
  bool get isDarkMode => AlifThemeProvider.isDarkModeOf(this);
}
