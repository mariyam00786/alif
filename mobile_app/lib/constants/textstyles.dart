import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class TypographySystem {
  static TextTheme get textTheme {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: pageTitle,
      displayMedium: sectionTitle,
      headlineMedium: cardTitle,
      bodyLarge: bodyText,
      bodyMedium: bodyText.copyWith(fontSize: 14),
      bodySmall: bodyText.copyWith(fontSize: 12),
      labelLarge: labelLarge,
      labelMedium: labelMedium,
    );
  }

  // Heading Font (Plus Jakarta Sans)
  static final TextStyle pageTitle = GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: ColorPalette.textPrimary,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static final TextStyle sectionTitle = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ColorPalette.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static final TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: ColorPalette.textPrimary,
    height: 1.3,
  );

  // Body Font (Plus Jakarta Sans)
  static final TextStyle bodyText = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: ColorPalette.textSecondary,
    height: 1.5,
  );

  // Labels
  static final TextStyle labelLarge = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
    letterSpacing: 0.1,
  );

  static final TextStyle labelMedium = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textTertiary,
    letterSpacing: 0.3,
  );

  // Micro-label (uppercase section headers)
  static final TextStyle microLabel = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: ColorPalette.textTertiary,
    letterSpacing: 0.8,
  );
}
