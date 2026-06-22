import 'package:flutter/material.dart';

import '../shared/theme/app_colors.dart';

/// Legacy color palette kept for backwards compatibility.
///
/// All values now delegate to [AppColors], the single source of truth.
/// New code should import and use [AppColors] directly.
class ColorPalette {
  // Brand Colors
  static const Color primaryDark = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color primaryMuted = AppColors.primaryMuted;

  // Accent Colors — warm gold
  static const Color secondary = AppColors.secondary;
  static const Color secondaryLight = AppColors.secondaryLight;
  static const Color secondaryMuted = AppColors.secondaryMuted;

  // Text Colors
  static const Color textPrimary = AppColors.heading;
  static const Color textSecondary = AppColors.body;
  static const Color textTertiary = AppColors.muted;
  static const Color textInverse = AppColors.textInverse;

  // Background Colors
  static const Color white = AppColors.surface;
  static const Color backgroundLight = AppColors.background;
  static const Color backgroundMuted = AppColors.surfaceMuted;
  static const Color backgroundDark = Color(0xFF162030);

  // Neutral Colors
  static const Color neutral50 = AppColors.neutral50;
  static const Color neutral100 = AppColors.neutral100;
  static const Color neutral200 = AppColors.neutral200;
  static const Color neutral300 = AppColors.neutral300;
  static const Color neutral400 = AppColors.neutral400;
  static const Color neutral500 = AppColors.neutral500;
  static const Color neutral600 = AppColors.neutral600;
  static const Color neutral700 = AppColors.neutral700;
  static const Color neutral800 = AppColors.neutral800;
  static const Color neutral900 = AppColors.neutral900;

  // Semantic Rating Colors
  static const Color ratingExcellent = AppColors.ratingExcellent;
  static const Color ratingSatisfactory = AppColors.ratingSatisfactory;
  static const Color ratingNeedsImprovement = AppColors.ratingNeedsImprovement;
  static const Color ratingNotDone = AppColors.ratingNotDone;
}
