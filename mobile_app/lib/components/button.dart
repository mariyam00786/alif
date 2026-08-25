import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/textstyles.dart';
import '../constants/dimensions.dart';

/// Button variant types
enum ButtonVariant {
  primary, // Main action button (green)
  secondary, // Secondary action (gold)
  outline, // Outlined style
  text, // Text-only (no background)
}

/// Button size variants
enum ButtonSize {
  small, // Compact buttons (tight padding)
  medium, // Standard buttons
  large, // Full-width or prominent buttons
}

/// Reusable Button Component
///
/// Features:
/// - Multiple variants: primary, secondary, outline, text
/// - Size variants: small, medium, large
/// - State handling: normal, hover, active, disabled
/// - Loading state with spinner
/// - Bilingual text support (English/Malayalam)
/// - Customizable colors and typography
///
/// Usage:
/// ```dart
/// AlifButton(
///   label: 'Submit',
///   onPressed: () { },
///   variant: ButtonVariant.primary,
///   size: ButtonSize.medium,
/// )
/// ```
class AlifButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final double? height;
  final Color? customColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final String? tooltip;
  final bool isMalayalam;

  const AlifButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.leading,
    this.trailing,
    this.width,
    this.height,
    this.customColor,
    this.textStyle,
    this.padding,
    this.borderRadius,
    this.elevation = 0,
    this.tooltip,
    this.isMalayalam = false,
  });

  @override
  State<AlifButton> createState() => _AlifButtonState();
}

class _AlifButtonState extends State<AlifButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Determine if button is interactive
    final isEnabled =
        !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    // Get colors based on variant
    final colors = _getButtonColors();

    // Get padding based on size
    final padding = widget.padding ?? _getPadding();

    // Get text style
    final textStyle = widget.textStyle ?? _getTextStyle();

    // Build button content
    final content = _buildButtonContent();

    // Wrap in Tooltip if provided
    Widget button = _buildButtonBase(
      colors: colors,
      padding: padding,
      textStyle: textStyle,
      content: content,
      isEnabled: isEnabled,
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }

  Widget _buildButtonBase({
    required Map<String, Color> colors,
    required EdgeInsets padding,
    required TextStyle textStyle,
    required Widget content,
    required bool isEnabled,
  }) {
    // Determine background and text color based on state
    Color backgroundColor = colors['background']!;
    Color textColor = colors['text']!;
    Color borderColor = colors['border'] ?? backgroundColor;

    if (!isEnabled) {
      backgroundColor = ColorPalette.neutral300;
      textColor = ColorPalette.neutral500;
      borderColor = ColorPalette.neutral300;
    } else if (_isPressed) {
      backgroundColor = colors['active']!;
      textColor = colors['text']!;
    } else if (_isHovered) {
      backgroundColor = colors['hover']!;
      textColor = colors['text']!;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return MouseRegion(
          onEnter: (_) => isEnabled ? setState(() => _isHovered = true) : null,
          onExit: (_) => setState(() => _isHovered = false),
          child: ElevatedButton(
            onPressed: isEnabled ? _handlePress : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              padding: padding,
              elevation: _isPressed ? widget.elevation : widget.elevation * 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              ),
              minimumSize: Size(widget.width ?? 0, widget.height ?? 48),
            ),
            child: content,
          ),
        );

      case ButtonVariant.secondary:
        return MouseRegion(
          onEnter: (_) => isEnabled ? setState(() => _isHovered = true) : null,
          onExit: (_) => setState(() => _isHovered = false),
          child: ElevatedButton(
            onPressed: isEnabled ? _handlePress : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              padding: padding,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              ),
              minimumSize: Size(widget.width ?? 0, widget.height ?? 48),
            ),
            child: content,
          ),
        );

      case ButtonVariant.outline:
        return MouseRegion(
          onEnter: (_) => isEnabled ? setState(() => _isHovered = true) : null,
          onExit: (_) => setState(() => _isHovered = false),
          child: OutlinedButton(
            onPressed: isEnabled ? _handlePress : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              padding: padding,
              side: BorderSide(color: borderColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              ),
              minimumSize: Size(widget.width ?? 0, widget.height ?? 48),
            ),
            child: content,
          ),
        );

      case ButtonVariant.text:
        return MouseRegion(
          onEnter: (_) => isEnabled ? setState(() => _isHovered = true) : null,
          onExit: (_) => setState(() => _isHovered = false),
          child: TextButton(
            onPressed: isEnabled ? _handlePress : null,
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              padding: padding,
              minimumSize: Size(widget.width ?? 0, widget.height ?? 48),
            ),
            child: content,
          ),
        );
    }
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_getButtonColors()['text']!),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          SizedBox(width: SpacingScale.sm),
        ],
        Text(
          widget.label,
          style: _getTextStyle(),
          textDirection: TextDirection.ltr,
        ),
        if (widget.trailing != null) ...[
          SizedBox(width: SpacingScale.sm),
          widget.trailing!,
        ],
      ],
    );
  }

  Map<String, Color> _getButtonColors() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return {
          'background': widget.customColor ?? ColorPalette.primaryDark,
          'hover': Color.fromARGB(
            255,
            (ColorPalette.primaryDark.r * 255 * 0.9).round(),
            (ColorPalette.primaryDark.g * 255 * 0.9).round(),
            (ColorPalette.primaryDark.b * 255 * 0.9).round(),
          ),
          'active': ColorPalette.primaryLight,
          'text': ColorPalette.white,
        };

      case ButtonVariant.secondary:
        return {
          'background': widget.customColor ?? ColorPalette.secondary,
          'hover': Color.fromARGB(
            255,
            (ColorPalette.secondary.r * 255 * 0.9).round(),
            (ColorPalette.secondary.g * 255 * 0.9).round(),
            (ColorPalette.secondary.b * 255 * 0.9).round(),
          ),
          'active': ColorPalette.primaryDark,
          'text': ColorPalette.white,
        };

      case ButtonVariant.outline:
        return {
          'background': ColorPalette.white,
          'hover': ColorPalette.neutral100,
          'active': ColorPalette.primaryDark,
          'border': ColorPalette.primaryDark,
          'text': ColorPalette.primaryDark,
        };

      case ButtonVariant.text:
        return {
          'background': Colors.transparent,
          'hover': ColorPalette.neutral100,
          'active': ColorPalette.neutral200,
          'text': widget.customColor ?? ColorPalette.primaryDark,
        };
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.md,
          vertical: SpacingScale.xs,
        );
      case ButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.lg,
          vertical: SpacingScale.md,
        );
      case ButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.xl,
          vertical: SpacingScale.lg,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ButtonSize.small:
        return TypographySystem.bodyText.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      case ButtonSize.medium:
        return TypographySystem.bodyText.copyWith(fontWeight: FontWeight.w600);
      case ButtonSize.large:
        return TypographySystem.sectionTitle.copyWith(
          fontWeight: FontWeight.w600,
        );
    }
  }

  void _handlePress() {
    if (mounted) {
      setState(() => _isPressed = true);
    }

    widget.onPressed?.call();

    Future.delayed(Duration(milliseconds: 200)).then((_) {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });
  }
}
