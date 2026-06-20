import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Card variant types
enum CardVariant {
  elevated,     // Elevated card with shadow
  outlined,     // Card with border only
  filled,       // Filled card with background
}

/// Reusable Card Component
/// 
/// Features:
/// - Multiple variants: elevated, outlined, filled
/// - Header, content, footer sections
/// - Customizable padding and margins
/// - Rounded corners
/// - Shadow support
/// - Click handler support
/// - Badge support (top-right corner)
/// - Bilingual text support
/// 
/// Usage:
/// ```dart
/// AlifCard(
///   variant: CardVariant.elevated,
///   header: Text('Card Title'),
///   child: Text('Card content'),
///   footer: AlifButton(label: 'Action', onPressed: () {}),
///   onTap: () { },
/// )
/// ```
class AlifCard extends StatefulWidget {
  final CardVariant variant;
  final Widget? header;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? elevation;
  final Widget? badge;
  final bool isClickable;

  const AlifCard({
    Key? key,
    this.variant = CardVariant.elevated,
    this.header,
    required this.child,
    this.footer,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.badge,
    this.isClickable = false,
  }) : super(key: key);

  @override
  State<AlifCard> createState() => _AlifCardState();
}

class _AlifCardState extends State<AlifCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    final padding = widget.padding ?? EdgeInsets.all(SpacingScale.lg);
    final margin = widget.margin ?? EdgeInsets.zero;

    Widget card = _buildCard(borderRadius, padding);

    if (widget.isClickable || widget.onTap != null) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: card,
        ),
      );
    }

    return Container(
      margin: margin,
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          card,
          // Badge (top-right corner)
          if (widget.badge != null)
            Positioned(
              top: -8,
              right: -8,
              child: widget.badge!,
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BorderRadius borderRadius, EdgeInsets padding) {
    switch (widget.variant) {
      case CardVariant.elevated:
        return Material(
          elevation: _isPressed ? 8 : (_isHovered ? 4 : 2),
          borderRadius: borderRadius,
          color: widget.backgroundColor ?? ColorPalette.white,
          child: _buildContent(padding),
        );

      case CardVariant.outlined:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.borderColor ?? ColorPalette.neutral300,
              width: 1,
            ),
            borderRadius: borderRadius,
            color: widget.backgroundColor ?? ColorPalette.white,
          ),
          child: _buildContent(padding),
        );

      case CardVariant.filled:
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? ColorPalette.neutral50,
            borderRadius: borderRadius,
          ),
          child: _buildContent(padding),
        );
    }
  }

  Widget _buildContent(EdgeInsets padding) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        if (widget.header != null) ...[
          Padding(
            padding: padding,
            child: widget.header!,
          ),
          if (widget.footer != null) Divider(height: 1),
        ],

        // Body
        Padding(
          padding: padding,
          child: widget.child,
        ),

        // Footer
        if (widget.footer != null) ...[
          if (widget.header != null) Divider(height: 1),
          Padding(
            padding: padding,
            child: widget.footer!,
          ),
        ],
      ],
    );
  }
}

/// Card builder for list items
/// Simplifies common card layout patterns
class AlifCardBuilder extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final CardVariant variant;
  final bool isDense;

  const AlifCardBuilder({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.variant = CardVariant.outlined,
    this.isDense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlifCard(
      variant: variant,
      onTap: onTap,
      isClickable: onTap != null,
      padding: EdgeInsets.symmetric(
        horizontal: SpacingScale.md,
        vertical: isDense ? SpacingScale.sm : SpacingScale.md,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: SpacingScale.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: SpacingScale.xs),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorPalette.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: SpacingScale.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Elevated card with icon and text (for stats, metrics)
class AlifStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AlifStatsCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlifCard(
      variant: CardVariant.elevated,
      backgroundColor: backgroundColor ?? ColorPalette.white,
      onTap: onTap,
      isClickable: onTap != null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor ?? ColorPalette.primaryDark,
            size: 32,
          ),
          SizedBox(height: SpacingScale.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorPalette.textPrimary,
            ),
          ),
          SizedBox(height: SpacingScale.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ColorPalette.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}
