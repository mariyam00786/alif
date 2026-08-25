import 'package:flutter/material.dart';

/// Typography tokens for the design system.
///
/// Provides semantic text styles (pageTitle, sectionTitle, cardTitle, bodyText)
/// aligned with the main design system's Inter font family.
class TypographySystem {
  TypographySystem._();

  static const String _fontFamily = 'Inter';

  /// Page-level heading (28px, bold)
  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFamily: _fontFamily,
  );

  /// Section heading (20px, semibold)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: _fontFamily,
  );

  /// Card heading (16px, semibold)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    fontFamily: _fontFamily,
  );

  /// Body text (16px, regular)
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: _fontFamily,
  );
}
