import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Quantity input size variants
enum QuantitySize {
  small,        // Compact size
  medium,       // Standard size
  large,        // Large size
}

/// Reusable Quantity Input Component
/// 
/// Features:
/// - +/- buttons with customizable increment
/// - Text input for direct value entry
/// - Min/max constraints
/// - Unit label support
/// - Disabled state
/// - Size variants
/// - Accessibility support
/// - Bilingual support
/// 
/// Usage:
/// ```dart
/// AlifQuantityInput(
///   value: 5,
///   onChanged: (value) { },
///   minValue: 0,
///   maxValue: 30,
///   unit: 'pages',
/// )
/// ```
class AlifQuantityInput extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;
  final int increment;
  final String? unit;
  final String? label;
  final bool isDisabled;
  final QuantitySize size;
  final Color? accentColor;
  final bool isMalayalam;
  final TextEditingController? controller;

  const AlifQuantityInput({
    Key? key,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 100,
    this.increment = 1,
    this.unit,
    this.label,
    this.isDisabled = false,
    this.size = QuantitySize.medium,
    this.accentColor,
    this.isMalayalam = false,
    this.controller,
  }) : super(key: key);

  @override
  State<AlifQuantityInput> createState() => _AlifQuantityInputState();
}

class _AlifQuantityInputState extends State<AlifQuantityInput> {
  late TextEditingController _controller;
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _controller = widget.controller ?? TextEditingController();
    _controller.text = _value.toString();
  }

  @override
  void didUpdateWidget(AlifQuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _value = widget.value;
      _controller.text = _value.toString();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? ColorPalette.primaryDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
            textDirection: widget.isMalayalam ? TextDirection.rtl : TextDirection.ltr,
          ),
          SizedBox(height: SpacingScale.sm),
        ],

        // Input container
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isDisabled ? ColorPalette.neutral200 : ColorPalette.neutral300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrease button
              _buildButton(
                icon: Icons.remove,
                onPressed: _value > widget.minValue ? _decrementValue : null,
                color: accentColor,
              ),

              // Text input
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isDisabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: _getInputPadding(),
                  ),
                  style: _getTextStyle(),
                  onChanged: _handleTextChange,
                ),
              ),

              // Increase button
              _buildButton(
                icon: Icons.add,
                onPressed: _value < widget.maxValue ? _incrementValue : null,
                color: accentColor,
              ),
            ],
          ),
        ),

        // Unit label
        if (widget.unit != null) ...[
          SizedBox(height: SpacingScale.sm),
          Text(
            widget.unit!,
            style: TextStyle(
              fontSize: 12,
              color: ColorPalette.neutral600,
            ),
            textDirection: widget.isMalayalam ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: _getButtonSize(),
      height: _getButtonSize(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? color : ColorPalette.neutral400,
          ),
        ),
      ),
    );
  }

  void _incrementValue() {
    final newValue = (_value + widget.increment).clamp(
      widget.minValue,
      widget.maxValue,
    );
    _updateValue(newValue);
  }

  void _decrementValue() {
    final newValue = (_value - widget.increment).clamp(
      widget.minValue,
      widget.maxValue,
    );
    _updateValue(newValue);
  }

  void _handleTextChange(String text) {
    if (text.isEmpty) return;

    try {
      final newValue = int.parse(text);
      if (newValue >= widget.minValue && newValue <= widget.maxValue) {
        _updateValue(newValue);
      } else {
        // Reset to previous value if out of range
        _controller.text = _value.toString();
      }
    } catch (e) {
      // Reset to previous value if invalid
      _controller.text = _value.toString();
    }
  }

  void _updateValue(int newValue) {
    setState(() {
      _value = newValue;
      _controller.text = _value.toString();
    });
    widget.onChanged(newValue);
  }

  EdgeInsets _getInputPadding() {
    switch (widget.size) {
      case QuantitySize.small:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.sm,
          vertical: SpacingScale.xs,
        );
      case QuantitySize.medium:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.md,
          vertical: SpacingScale.sm,
        );
      case QuantitySize.large:
        return EdgeInsets.symmetric(
          horizontal: SpacingScale.lg,
          vertical: SpacingScale.md,
        );
    }
  }

  double _getButtonSize() {
    switch (widget.size) {
      case QuantitySize.small:
        return 32;
      case QuantitySize.medium:
        return 40;
      case QuantitySize.large:
        return 48;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case QuantitySize.small:
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ColorPalette.textPrimary,
        );
      case QuantitySize.medium:
        return TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ColorPalette.textPrimary,
        );
      case QuantitySize.large:
        return TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ColorPalette.textPrimary,
        );
    }
  }
}

/// Stepper component with +/- and value display
/// More compact than QuantityInput
class AlifStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;
  final int increment;
  final bool isDisabled;
  final Color? accentColor;

  const AlifStepper({
    Key? key,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 100,
    this.increment = 1,
    this.isDisabled = false,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? ColorPalette.primaryDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrease button
        GestureDetector(
          onTap: value > minValue && !isDisabled
              ? () => onChanged(value - increment)
              : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorPalette.white,
              border: Border.all(
                color: ColorPalette.neutral300,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.remove,
              size: 18,
              color: value > minValue && !isDisabled
                  ? color
                  : ColorPalette.neutral400,
            ),
          ),
        ),
        SizedBox(width: SpacingScale.sm),

        // Value display
        SizedBox(
          width: 40,
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ColorPalette.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: SpacingScale.sm),

        // Increase button
        GestureDetector(
          onTap: value < maxValue && !isDisabled
              ? () => onChanged(value + increment)
              : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorPalette.white,
              border: Border.all(
                color: ColorPalette.neutral300,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: value < maxValue && !isDisabled
                  ? color
                  : ColorPalette.neutral400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Slider-based quantity input
class AlifSliderQuantity extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;
  final String? label;
  final String? unit;
  final bool isDisabled;

  const AlifSliderQuantity({
    Key? key,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 100,
    this.label,
    this.unit,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
              Text(
                '$value ${unit ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingScale.md),
        ],
        Slider(
          value: value.toDouble(),
          onChanged: isDisabled ? null : (v) => onChanged(v.toInt()),
          min: minValue.toDouble(),
          max: maxValue.toDouble(),
          divisions: maxValue - minValue,
          label: '$value',
          activeColor: ColorPalette.primaryDark,
          inactiveColor: ColorPalette.neutral300,
        ),
      ],
    );
  }
}
