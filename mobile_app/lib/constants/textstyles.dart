import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/theme/app_text_styles.dart';

/// Legacy typography system kept for backwards compatibility.
///
/// All styles now delegate to [AppTextStyles], the single source of truth.
/// New code should import and use [AppTextStyles] directly.
class TypographySystem {
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: pageTitle,
      displayMedium: sectionTitle,
      headlineMedium: cardTitle,
      bodyLarge: bodyText,
      bodyMedium: bodyText.copyWith(fontSize: 14),
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
    );
  }

  static final TextStyle pageTitle = AppTextStyles.pageTitle;
  static final TextStyle sectionTitle = AppTextStyles.sectionTitle;
  static final TextStyle cardTitle = AppTextStyles.cardTitle;
  static final TextStyle bodyText = AppTextStyles.body;
  static final TextStyle labelLarge = AppTextStyles.label;
  static final TextStyle labelMedium = AppTextStyles.labelSmall;
  static final TextStyle microLabel = AppTextStyles.microLabel;
}
