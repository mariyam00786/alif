import 'package:flutter/material.dart';

/// Typography system for Alif School
class AppTypography {
  // Private constructor
  AppTypography._();

  // Font families
  static const String fontFamilyEnglish = 'Inter';
  static const String fontFamilyMalayalam = 'Manjari';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Display styles
  static TextStyle displayLarge({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 40,
    fontWeight: bold,
    height: 1.2,
    fontFamily: fontFamily,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 32,
    fontWeight: bold,
    height: 1.25,
    fontFamily: fontFamily,
    letterSpacing: -0.25,
  );

  static TextStyle displaySmall({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.3,
    fontFamily: fontFamily,
  );

  // Heading styles
  static TextStyle headlineLarge({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 32,
    fontWeight: semiBold,
    height: 1.25,
    fontFamily: fontFamily,
  );

  static TextStyle headlineMedium({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.3,
    fontFamily: fontFamily,
  );

  static TextStyle headlineSmall({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.35,
    fontFamily: fontFamily,
  );

  // Title styles
  static TextStyle titleLarge({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.4,
    fontFamily: fontFamily,
  );

  static TextStyle titleMedium({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static TextStyle titleSmall({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.57,
    fontFamily: fontFamily,
  );

  // Body styles
  static TextStyle bodyLarge({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static TextStyle bodyMedium({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.57,
    fontFamily: fontFamily,
  );

  static TextStyle bodySmall({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.67,
    fontFamily: fontFamily,
  );

  // Label styles
  static TextStyle labelLarge({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.57,
    fontFamily: fontFamily,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.67,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 11,
    fontWeight: medium,
    height: 1.82,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  // Caption style
  static TextStyle caption({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 11,
    fontWeight: regular,
    height: 1.6,
    fontFamily: fontFamily,
  );

  // Overline style
  static TextStyle overline({String fontFamily = fontFamilyEnglish}) => TextStyle(
    fontSize: 10,
    fontWeight: semiBold,
    height: 1.6,
    fontFamily: fontFamily,
    letterSpacing: 1.5,
    textBaseline: TextBaseline.alphabetic,
  );
}
