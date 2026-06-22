import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';

/// Badge variant types
enum BadgeVariant {
  success, // Green - positive state
  warning, // Orange - caution state
  error, // Red - error state
  info, // Blue - informational
  neutral, // Gray - neutral state
}

/// Badge size variants
enum BadgeSize {
  small, // Compact badge
  medium, // Standard badge
  large, // Large badge
}

/// Reusable Badge Component
///
/// Features:
/// - Multiple variants: success, warning, error, info, neutral
/// - Size variants: small, medium, large
/// - Text and icon support
/// - Customizable colors
/// - Dismissible badges (with close button)
/// - Bilingual text support
/// - Animation support
///
/// Usage:
/// ```dart
/// AlifBadge(
///   label: 'Active',
///   variant: BadgeVariant.success,
///   size: BadgeSize.medium,
/// )
/// ```
class AlifBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final BadgeSize size;
  final Widget? icon;
  final VoidCallback? onClose;
  final Color? customBackgroundColor;
  final Color? customTextColor;
  final bool isMalayalam;

  const AlifBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.size = BadgeSize.medium,
    this.icon,
    this.onClose,
    this.customBackgroundColor,
    this.customTextColor,
    this.isMalayalam = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getVariantColors();
    final backgroundColor = customBackgroundColor ?? colors['background']!;
    final textColor = customTextColor ?? colors['text']!;

    final padding = _getPadding();
    final fontSize = _getFontSize();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SizedBox(width: fontSize, height: fontSize, child: icon),
            SizedBox(width: SpacingScale.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textDirection: TextDirection.ltr,
          ),
          if (onClose != null) ...[
            SizedBox(width: SpacingScale.xs),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, size: fontSize, color: textColor),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, Color> _getVariantColors() {
    switch (variant) {
      case BadgeVariant.success:
        return {
          'background': ColorPalette.ratingExcellent.withValues(alpha: 0.1),
          'text': ColorPalette.ratingExcellent,
        };
      case BadgeVariant.warning:
        return {
          'background': ColorPalette.ratingSatisfactory.withValues(alpha: 0.1),
          'text': ColorPalette.ratingSatisfactory,
        };
      case BadgeVariant.error:
        return {
          'background': ColorPalette.ratingNeedsImprovement.withValues(
            alpha: 0.1,
          ),
          'text': ColorPalette.ratingNeedsImprovement,
        };
      case BadgeVariant.info:
        return {
          'background': ColorPalette.primaryDark.withValues(alpha: 0.1),
          'text': ColorPalette.primaryDark,
        };
      case BadgeVariant.neutral:
        return {
          'background': ColorPalette.neutral200,
          'text': ColorPalette.neutral700,
        };
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.sm,
          vertical: SpacingScale.xs,
        );
      case BadgeSize.medium:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.md,
          vertical: SpacingScale.sm,
        );
      case BadgeSize.large:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.lg,
          vertical: SpacingScale.md,
        );
    }
  }

  double _getFontSize() {
    switch (size) {
      case BadgeSize.small:
        return 11;
      case BadgeSize.medium:
        return 12;
      case BadgeSize.large:
        return 14;
    }
  }
}

/// Circular badge for counts/notifications
/// Used as notification indicator (top-right corner of icons)
class AlifCircleBadge extends StatelessWidget {
  final String count;
  final Color? backgroundColor;
  final Color? textColor;

  const AlifCircleBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: backgroundColor ?? ColorPalette.ratingNeedsImprovement,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count.length > 2 ? '${count.substring(0, 2)}+' : count,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor ?? ColorPalette.white,
          ),
        ),
      ),
    );
  }
}

/// Status badge with dot indicator
class AlifStatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? activeColor;
  final Color? inactiveColor;

  const AlifStatusBadge({
    super.key,
    required this.label,
    required this.isActive,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive
        ? (activeColor ?? ColorPalette.ratingExcellent).withValues(alpha: 0.1)
        : (inactiveColor ?? ColorPalette.neutral200);

    final textColor = isActive
        ? (activeColor ?? ColorPalette.ratingExcellent)
        : ColorPalette.neutral700;

    final dotColor = isActive
        ? (activeColor ?? ColorPalette.ratingExcellent)
        : ColorPalette.neutral500;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: SpacingScale.md,
        vertical: SpacingScale.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: SpacingScale.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rating badge showing rating name and color
class AlifRatingBadge extends StatelessWidget {
  final String ratingName;
  final int marks;
  final BadgeVariant variant;

  const AlifRatingBadge({
    super.key,
    required this.ratingName,
    required this.marks,
    this.variant = BadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return AlifBadge(
      label: '$ratingName ($marks)',
      variant: variant,
      size: BadgeSize.medium,
      icon: Icon(_getIconForRating(ratingName), size: 12),
    );
  }

  IconData _getIconForRating(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Icons.star;
      case 'satisfactory':
        return Icons.check;
      case 'needs improvement':
        return Icons.warning;
      case 'not done':
        return Icons.close;
      default:
        return Icons.label;
    }
  }
}
