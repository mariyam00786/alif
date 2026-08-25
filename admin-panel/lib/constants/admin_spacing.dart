import 'package:flutter/material.dart';

/// Centralized spacing tokens for the Alif admin panel.
///
/// Use these instead of ad-hoc `EdgeInsets`/`SizedBox` magic numbers so the
/// visual rhythm stays consistent across every screen. Values follow a 4px
/// baseline scale.
class AdminSpacing {
  const AdminSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Common reusable gaps.
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);
  static const SizedBox gapXxxl = SizedBox(height: xxxl);

  // Common card interior paddings.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding =
      EdgeInsets.symmetric(horizontal: xl, vertical: lg);
}
