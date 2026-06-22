import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized, reusable container decorations for the Alif mobile app.
///
/// Keeps the visual language minimal and consistent: soft white surfaces,
/// hairline borders and gentle (or no) shadows. Reference [AppDecorations]
/// instead of building ad-hoc [BoxDecoration]s in each screen.
class AppDecorations {
  AppDecorations._();

  // ── Radii ────────────────────────────────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusFull = 28;

  static BorderRadius get brSm => BorderRadius.circular(radiusSm);
  static BorderRadius get brMd => BorderRadius.circular(radiusMd);
  static BorderRadius get brLg => BorderRadius.circular(radiusLg);
  static BorderRadius get brFull => BorderRadius.circular(radiusFull);

  // ── Borders ──────────────────────────────────────────────────────────────
  static Border get hairline => Border.all(color: AppColors.border, width: 1);
  static Border get hairlineSoft =>
      Border.all(color: AppColors.borderSoft, width: 1);

  // ── Shadows (soft, airy floating-card look) ──────────────────────────────
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Whisper-soft ambient shadow for bordered "flat" cards so they lift
  /// gently off the background instead of looking pasted on.
  static const List<BoxShadow> ambient = [
    BoxShadow(
      color: Color(0x0A14110D),
      blurRadius: 14,
      offset: Offset(0, 6),
      spreadRadius: -6,
    ),
  ];

  /// Soft diffuse elevation used by floating cards (StatTiles, summaries).
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x12101729),
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: -10,
    ),
    BoxShadow(color: Color(0x0A101729), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Flat minimal card: white surface, hairline border + whisper shadow.
  static BoxDecoration card({
    Color color = AppColors.surface,
    double radius = radiusLg,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderSoft, width: 1),
      boxShadow: ambient,
    );
  }

  /// Slightly elevated card: white surface, soft shadow, no border.
  static BoxDecoration softCard({
    Color color = AppColors.surface,
    double radius = radiusLg,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: soft,
    );
  }

  /// Input field surface: white background, hairline border, soft radius.
  static BoxDecoration inputField({
    Color color = AppColors.surface,
    double radius = radiusMd,
    Color borderColor = AppColors.border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
    );
  }

  /// Tinted "chip" / pill surface, e.g. for icon backgrounds.
  static BoxDecoration tinted(
    Color color, {
    double radius = radiusSm,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Rounded pill (stadium) surface.
  static BoxDecoration pill({Color color = AppColors.primaryMuted}) {
    return BoxDecoration(color: color, borderRadius: brFull);
  }
}

/// Reusable minimal card container used across every screen.
///
/// Wraps [child] in a padded surface that uses [AppDecorations]. Set
/// [elevated] to `true` for a soft-shadow variant instead of the default
/// flat bordered look.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final bool elevated;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppDecorations.radiusLg,
    this.color = AppColors.surface,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = elevated
        ? AppDecorations.softCard(color: color, radius: radius)
        : AppDecorations.card(color: color, radius: radius);

    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
