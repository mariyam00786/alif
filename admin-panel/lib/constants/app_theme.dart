import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAlifAdminTheme() {
  // MsgHex EXACT color scheme (extracted from msghex.com)
  const primaryDark = Color(0xFF2D5A34); // Primary green (rgb 45,90,52)
  const accentGreen = Color(
    0xFF74B385,
  ); // Accent green border (rgb 116,179,133)
  const backgroundSlate = Color(0xFFF4F8F4); // Background (rgb 244,248,244)
  const surfaceWhite = Colors.white;
  const textPrimary = Color(0xFF111827); // Heading (rgb 17,24,39)
  const textSecondary = Color(0xFF1F2937); // Body text (rgb 31,41,55)
  const sidebarDark = Color(0xFF14241A); // Foreground dark green
  const borderLight = Color(0xFFE5E7EB); // Light gray border (rgb 229,231,235)

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryDark,
    primary: primaryDark,
    secondary: accentGreen,
    surface: surfaceWhite,
    tertiary: primaryDark,
  );

  // Typography - Plus Jakarta Sans (msghex's exact font)
  final outfitTextTheme = GoogleFonts.plusJakartaSansTextTheme();
  final interTextTheme = GoogleFonts.plusJakartaSansTextTheme();
  final String? jakartaFont = GoogleFonts.plusJakartaSans().fontFamily;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundSlate,
    textTheme: interTextTheme.copyWith(
      headlineLarge: outfitTextTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineMedium: outfitTextTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      titleLarge: outfitTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.4,
      ),
      titleMedium: outfitTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyLarge: interTextTheme.bodyLarge?.copyWith(
        fontSize: 15,
        color: textSecondary,
        height: 1.5,
      ),
      bodyMedium: interTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: textSecondary,
        height: 1.45,
      ),
      bodySmall: interTextTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: const Color(0xFF64748B),
        height: 1.4,
      ),
      labelLarge: interTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: interTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: textPrimary),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: sidebarDark,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 6,
      shadowColor: const Color(0xFF112617).withValues(alpha: 0.10),
      surfaceTintColor: Colors.transparent,
      color: surfaceWhite,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderLight.withValues(alpha: 0.8), width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: borderLight,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 10,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryDark.withValues(alpha: 0.07),
      selectedColor: primaryDark.withValues(alpha: 0.14),
      disabledColor: borderLight,
      side: BorderSide(color: primaryDark.withValues(alpha: 0.18), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        letterSpacing: 0.1,
        color: primaryDark,
        fontFamily: jakartaFont,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryDark, width: 1.8),
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: primaryDark.withValues(alpha: 0.45),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.1,
          fontFamily: jakartaFont,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: primaryDark.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.1,
          fontFamily: jakartaFont,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        backgroundColor: surfaceWhite,
        side: const BorderSide(color: borderLight, width: 1.4),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.1,
          fontFamily: jakartaFont,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        minimumSize: const Size(48, 48),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontFamily: jakartaFont,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
      headingTextStyle: TextStyle(
        fontFamily: jakartaFont,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
        letterSpacing: 0.6,
      ),
      dataTextStyle: TextStyle(
        fontFamily: jakartaFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.35,
      ),
      dividerThickness: 1,
      horizontalMargin: 16,
      columnSpacing: 20,
      headingRowHeight: 54,
      dataRowMinHeight: 62,
      dataRowMaxHeight: 72,
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark.withValues(alpha: 0.05);
        }
        return null;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: sidebarDark,
      contentTextStyle: TextStyle(color: Colors.white, fontFamily: jakartaFont),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
