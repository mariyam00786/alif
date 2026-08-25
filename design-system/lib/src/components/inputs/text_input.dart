import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Text input field widget
class TextInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final bool required;
  final int? maxLength;
  final TextInputType keyboardType;
  final bool enabled;
  final int minLines;
  final int maxLines;

  const TextInput({
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.required = false,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 1,
    Key? key,
  }) : super(key: key);

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  late FocusNode _focusNode;
  // ignore: unused_field
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: widget.label,
                  style: AppTypography.labelLarge(
                    fontFamily: 'Inter',
                  ),
                ),
                if (widget.required)
                  TextSpan(
                    text: ' *',
                    style: AppTypography.labelLarge(fontFamily: 'Inter').copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          style: AppTypography.bodyMedium(fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.textSecondary)
                : null,
            suffixIcon: widget.suffixIcon != null
                ? Icon(widget.suffixIcon, color: AppColors.textSecondary)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.grey400,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.grey400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
