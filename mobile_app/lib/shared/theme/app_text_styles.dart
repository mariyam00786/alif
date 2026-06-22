import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized, reusable text styles for the Alif mobile app.
///
/// Every screen should reference [AppTextStyles] instead of declaring inline
/// `TextStyle(...)` objects, so typography stays consistent and minimal.
/// All styles use Inter (the app's brand font).
class AppTextStyles {
  AppTextStyles._();

  // ── Design-system canonical styles ─────────────────────────────────────
  // Per the design system guide: Heading 20/SemiBold, Title 16/Medium,
  // Body 14/Regular, Caption 12/Regular.

  /// Heading — 20px, SemiBold.
  static final TextStyle heading = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
    height: 1.3,
  );

  /// Title — 16px, Medium.
  static final TextStyle title = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.heading,
    height: 1.4,
  );

  /// Caption — 12px, Regular.
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.4,
  );

  // ── Extended styles (mapped onto the same minimal scale) ───────────────

  /// Large page / screen title.
  static final TextStyle pageTitle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// Section heading within a screen.
  static final TextStyle sectionTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
    height: 1.4,
  );

  /// Title used inside a card.
  static final TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
    height: 1.3,
  );

  /// Big bold numeric stat value.
  static final TextStyle statNumber = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.heading,
    height: 1.0,
  );

  /// Default body text.
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.body,
    height: 1.5,
  );

  /// Smaller secondary body text.
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.4,
  );

  /// Emphasized inline label.
  static final TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
    letterSpacing: 0.1,
  );

  /// Small muted label (e.g. under a stat number).
  static final TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
    letterSpacing: 0.2,
  );

  /// Uppercase micro section header.
  static final TextStyle microLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
    letterSpacing: 0.6,
  );

  /// Button label.
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
