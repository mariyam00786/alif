/// Spacing system based on 4px base unit
class AppSpacing {
  // Private constructor
  AppSpacing._();

  // Base unit: 4px
  static const double baseUnit = 4.0;

  // Spacing values
  static const double xs = baseUnit * 1; // 4px
  static const double sm = baseUnit * 2; // 8px
  static const double md = baseUnit * 3; // 12px
  static const double base = baseUnit * 4; // 16px
  static const double lg = baseUnit * 6; // 24px
  static const double xl = baseUnit * 8; // 32px
  static const double xxl = baseUnit * 10; // 40px
  static const double xxxl = baseUnit * 12; // 48px

  // Component-specific spacing
  static const double buttonHorizontalPadding = base;
  static const double buttonVerticalPadding = md;

  static const double inputHorizontalPadding = base;
  static const double inputVerticalPadding = md;

  static const double cardPadding = base;
  static const double cardCompactPadding = md;
  static const double cardSpaciousPadding = lg;

  static const double modalPadding = lg;
  static const double modalHeaderPadding = base;

  // Gap spacing
  static const double gapXs = xs;
  static const double gapSm = sm;
  static const double gapMd = md;
  static const double gapBase = base;
  static const double gapLg = lg;
  static const double gapXl = xl;

  // Responsive gaps (adjust based on screen size)
  static double responsiveGap({
    required double width,
    double mobileGap = base,
    double tabletGap = lg,
    double desktopGap = xl,
  }) {
    if (width < 600) return mobileGap;
    if (width < 1024) return tabletGap;
    return desktopGap;
  }
}
