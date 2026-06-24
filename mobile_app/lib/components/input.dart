import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/textstyles.dart';
import '../constants/dimensions.dart';

/// Input field type
enum InputType {
  text, // Regular text input
  email, // Email input
  password, // Masked password input
  phone, // Phone number (with formatting)
  number, // Numeric input
  multiline, // Multiline text area
}

/// Reusable Input Component
///
/// Features:
/// - Multiple input types: text, email, password, phone, number, multiline
/// - State handling: normal, focused, error, disabled
/// - Label and hint support (bilingual)
/// - Character counter
/// - Error message display
/// - Icon support (leading/trailing)
/// - Required field indicator
/// - Input formatting (phone numbers, numbers)
/// - Accessibility support
///
/// Usage:
/// ```dart
/// AlifInput(
///   label: 'Full Name',
///   placeholder: 'Enter your name',
///   type: InputType.text,
///   onChanged: (value) { },
///   required: true,
/// )
/// ```
class AlifInput extends StatefulWidget {
  final String label;
  final String placeholder;
  final InputType type;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? helperText;
  final int? maxLength;
  final int? minLength;
  final bool required;
  final bool isDisabled;
  final TextEditingController? controller;
  final Widget? leading;
  final Widget? trailing;
  final InputDecoration? customDecoration;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final bool showCounter;
  final String? Function(String?)? validator;
  final bool isMalayalam;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  const AlifInput({
    super.key,
    required this.label,
    this.placeholder = '',
    this.type = InputType.text,
    this.onChanged,
    this.errorText,
    this.helperText,
    this.maxLength,
    this.minLength,
    this.required = false,
    this.isDisabled = false,
    this.controller,
    this.leading,
    this.trailing,
    this.customDecoration,
    this.textStyle,
    this.hintStyle,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.showCounter = false,
    this.validator,
    this.isMalayalam = false,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AlifInput> createState() => _AlifInputState();
}

class _AlifInputState extends State<AlifInput> {
  /// Fallback controller used only when the caller does not supply one.
  ///
  /// It is always allocated (and always disposed) so that [_controller] can
  /// safely fall back to it at any time. The active controller is resolved on
  /// every build via the getter below, which means that if Flutter reuses this
  /// State for a field that now points at a *different* `widget.controller`
  /// (e.g. when a form inserts/removes a field above this one), the text always
  /// stays bound to the correct controller instead of a stale one.
  final TextEditingController _fallbackController = TextEditingController();

  TextEditingController get _controller =>
      widget.controller ?? _fallbackController;

  bool _isFocused = false;
  bool _isPasswordVisible = false;
  String? _validationError;

  @override
  void dispose() {
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty) ...[
          Row(
            children: [
              Text(
                widget.label,
                style: TypographySystem.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
                textDirection: TextDirection.ltr,
              ),
              if (widget.required) ...[
                SizedBox(width: SpacingScale.xs),
                Text(
                  '*',
                  style: TextStyle(color: ColorPalette.ratingNeedsImprovement),
                ),
              ],
            ],
          ),
          SizedBox(height: SpacingScale.xs),
        ],

        // Input field
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: TextFormField(
            controller: _controller,
            enabled: !widget.isDisabled,
            onChanged: (value) {
              widget.onChanged?.call(value);
              _validateInput(value);
            },
            validator: widget.validator,
            obscureText:
                widget.type == InputType.password && !_isPasswordVisible,
            keyboardType: _getKeyboardType(),
            inputFormatters: _getInputFormatters(),
            autofillHints: widget.autofillHints,
            textCapitalization: widget.textCapitalization,
            maxLength: widget.maxLength,
            maxLines: widget.type == InputType.password ? 1 : widget.maxLines,
            minLines:
                widget.minLines ?? (widget.type == InputType.multiline ? 4 : 1),
            textInputAction: widget.textInputAction,
            textDirection: TextDirection.ltr,
            style:
                widget.textStyle ??
                TypographySystem.bodyText.copyWith(
                  color: widget.isDisabled
                      ? ColorPalette.neutral500
                      : ColorPalette.textPrimary,
                ),
            decoration: _buildDecoration(),
          ),
        ),

        // Character counter (if enabled and not using built-in counter)
        if (widget.showCounter && widget.maxLength != null) ...[
          SizedBox(height: SpacingScale.xs),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '${_controller.text.length}/${widget.maxLength}',
              style: TypographySystem.bodyText.copyWith(
                fontSize: 12,
                color: ColorPalette.neutral600,
              ),
            ),
          ),
        ],

        // Error message
        if (_validationError != null) ...[
          SizedBox(height: SpacingScale.xs),
          Text(
            _validationError!,
            style: TypographySystem.bodyText.copyWith(
              fontSize: 12,
              color: ColorPalette.ratingNeedsImprovement,
            ),
          ),
        ],

        // Helper text
        if (widget.helperText != null && _validationError == null) ...[
          SizedBox(height: SpacingScale.xs),
          Text(
            widget.helperText!,
            style: TypographySystem.bodyText.copyWith(
              fontSize: 12,
              color: ColorPalette.neutral600,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildDecoration() {
    final borderColor = _isFocused
        ? ColorPalette.primaryDark
        : (_validationError != null
              ? ColorPalette.ratingNeedsImprovement
              : ColorPalette.neutral300);

    final focusedBorderColor = _validationError != null
        ? ColorPalette.ratingNeedsImprovement
        : ColorPalette.primaryDark;

    return InputDecoration(
      hintText: widget.placeholder,
      hintStyle:
          widget.hintStyle ??
          TypographySystem.bodyText.copyWith(color: ColorPalette.neutral500),
      prefixIcon: widget.leading,
      suffixIcon: _buildSuffixIcon(),
      contentPadding: EdgeInsets.symmetric(
        horizontal: SpacingScale.md,
        vertical: SpacingScale.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: widget.isDisabled ? ColorPalette.neutral200 : borderColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusedBorderColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: ColorPalette.ratingNeedsImprovement,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: ColorPalette.ratingNeedsImprovement,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: widget.isDisabled
          ? ColorPalette.neutral100
          : ColorPalette.white,
      counterText: '', // Hide default counter
      errorText: widget.errorText,
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.type == InputType.password) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: ColorPalette.neutral600,
        ),
        onPressed: () {
          setState(() => _isPasswordVisible = !_isPasswordVisible);
        },
      );
    }

    if (widget.trailing != null) {
      return widget.trailing;
    }

    return null;
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case InputType.email:
        return TextInputType.emailAddress;
      case InputType.phone:
        return TextInputType.phone;
      case InputType.number:
        return TextInputType.number;
      case InputType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (widget.type) {
      case InputType.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ];
      case InputType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return [];
    }
  }

  void _validateInput(String value) {
    String? error;

    // Required field validation
    if (widget.required && value.isEmpty) {
      error = '${widget.label} is required';
    }

    // Email validation
    if (widget.type == InputType.email && value.isNotEmpty) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(value)) {
        error = 'Please enter a valid email';
      }
    }

    // Phone validation
    if (widget.type == InputType.phone && value.isNotEmpty) {
      if (value.length < 10) {
        error = 'Please enter a valid phone number';
      }
    }

    // Min length validation
    if (widget.minLength != null &&
        value.isNotEmpty &&
        value.length < widget.minLength!) {
      error = 'Minimum ${widget.minLength} characters required';
    }

    // Custom validator
    if (widget.validator != null && error == null) {
      error = widget.validator!(value);
    }

    setState(() => _validationError = error);
  }
}
