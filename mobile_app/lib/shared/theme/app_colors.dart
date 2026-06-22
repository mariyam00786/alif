import 'package:flutter/material.dart';

/// Centralized, reusable color palette for the Alif mobile app.
///
/// This is the single source of truth for every color used across screens.
/// Prefer referencing [AppColors] instead of hard-coding `Color(0x...)`
/// literals so the whole app stays visually consistent and easy to retheme.
class AppColors {
  AppColors._();

  // ── Brand (teal) ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryMuted = Color(0xFFE6F4F2);
  static const Color primaryDeep = Color(0xFF115E59);

  // ── Accent (sage green) ──────────────────────────────────────────────────
  static const Color secondary = Color(0xFFA7C4A0);
  static const Color secondaryLight = Color(0xFFC5DAC0);
  static const Color secondaryMuted = Color(0xFFEEF4EC);

  // ── Secondary gold (decorative accents) ──────────────────────────────────
  static const Color gold = Color(0xFFC9A227);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color heading = Color(0xFF1F2937); // Text Primary
  static const Color body = Color(0xFF374151);
  static const Color muted = Color(0xFF6B7280); // Text Secondary
  static const Color textInverse = Colors.white;

  // ── Surfaces & backgrounds ───────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAF9F6); // Soft warm off-white
  static const Color backgroundSecondary = Color(0xFFF1F5F4); // Soft teal tint
  static const Color surfaceMuted = Color(0xFFF1F4F1);

  // ── Borders & dividers ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSoft = Color(0xFFEDEFF2);

  // ── Semantic status colors ───────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  // ── Neutral scale ────────────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // ── Semantic rating colors ───────────────────────────────────────────────
  static const Color ratingExcellent = Color(0xFF059669);
  static const Color ratingSatisfactory = Color(0xFF2563EB);
  static const Color ratingNeedsImprovement = Color(0xFFDC2626);
  static const Color ratingNotDone = Color(0xFF9CA3AF);

  // ── Shared shadow color ──────────────────────────────────────────────────
  static const Color shadow = Color(0x0F101729);
}
