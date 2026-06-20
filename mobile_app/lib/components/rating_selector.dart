import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';

/// Rating selector configuration
class RatingOption {
  final String id;
  final String label;
  final String labelMalayalam;
  final int marks;
  final Color color;
  final IconData icon;

  RatingOption({
    required this.id,
    required this.label,
    required this.labelMalayalam,
    required this.marks,
    required this.color,
    required this.icon,
  });
}

/// Reusable Rating Selector Component
///
/// Features:
/// - 4-option rating system (Excellent, Satisfactory, Needs Improvement, Not Done)
/// - Visual feedback with colors
/// - Icon indicators
/// - Marks display
/// - Bilingual support
/// - Disabled state support
/// - Single or multiple selection
///
/// Usage:
/// ```dart
/// AlifRatingSelector(
///   value: selectedRatingId,
///   onChanged: (ratingId) { },
///   options: [
///     RatingOption(...),
///     RatingOption(...),
///   ],
/// )
/// ```
class AlifRatingSelector extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final List<RatingOption> options;
  final bool isDisabled;
  final bool vertical;
  final String? label;
  final bool required;
  final bool isMalayalam;
  final double? cardElevation;

  const AlifRatingSelector({
    super.key,
    this.value,
    required this.onChanged,
    required this.options,
    this.isDisabled = false,
    this.vertical = false,
    this.label,
    this.required = false,
    this.isMalayalam = false,
    this.cardElevation = 2,
  });

  @override
  State<AlifRatingSelector> createState() => _AlifRatingSelectorState();
}

class _AlifRatingSelectorState extends State<AlifRatingSelector> {
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.value;
  }

  @override
  void didUpdateWidget(AlifRatingSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedId = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
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
          SizedBox(height: SpacingScale.md),
        ],

        // Rating options
        widget.vertical ? _buildVerticalLayout() : _buildHorizontalLayout(),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        for (int i = 0; i < widget.options.length; i++) ...[
          Expanded(child: _buildRatingCard(widget.options[i])),
          if (i < widget.options.length - 1) SizedBox(width: SpacingScale.sm),
        ],
      ],
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        for (int i = 0; i < widget.options.length; i++) ...[
          _buildRatingCard(widget.options[i]),
          if (i < widget.options.length - 1) SizedBox(height: SpacingScale.md),
        ],
      ],
    );
  }

  Widget _buildRatingCard(RatingOption option) {
    final isSelected = _selectedId == option.id;

    return GestureDetector(
      onTap: widget.isDisabled
          ? null
          : () {
              setState(() => _selectedId = option.id);
              widget.onChanged(option.id);
            },
      child: Material(
        elevation: isSelected
            ? widget.cardElevation! + 2
            : widget.cardElevation!,
        color: isSelected ? option.color : ColorPalette.white,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? option.color : ColorPalette.neutral300,
              width: isSelected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(SpacingScale.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                option.icon,
                size: 32,
                color: isSelected ? ColorPalette.white : option.color,
              ),
              SizedBox(height: SpacingScale.sm),

              // Label
              Text(
                widget.isMalayalam ? option.labelMalayalam : option.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? ColorPalette.white : option.color,
                ),
                textDirection: widget.isMalayalam
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
              SizedBox(height: SpacingScale.xs),

              // Marks
              Text(
                '${option.marks} marks',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? ColorPalette.white.withValues(alpha: 0.8)
                      : ColorPalette.neutral600,
                ),
              ),

              // Checkmark for selected
              if (isSelected) ...[
                SizedBox(height: SpacingScale.sm),
                Icon(Icons.check_circle, color: ColorPalette.white, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard 4-option rating selector
/// Pre-configured with Excellent, Satisfactory, Needs Improvement, Not Done
class AlifStandardRatingSelector extends StatelessWidget {
  final String? selectedRatingId;
  final ValueChanged<String> onChanged;
  final bool isDisabled;
  final bool vertical;
  final bool isMalayalam;
  final String? label;

  const AlifStandardRatingSelector({
    super.key,
    this.selectedRatingId,
    required this.onChanged,
    this.isDisabled = false,
    this.vertical = false,
    this.isMalayalam = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AlifRatingSelector(
      value: selectedRatingId,
      onChanged: onChanged,
      isDisabled: isDisabled,
      vertical: vertical,
      isMalayalam: isMalayalam,
      label: label,
      options: [
        RatingOption(
          id: 'rating-excellent',
          label: 'Excellent',
          labelMalayalam: 'ഉത്തമം',
          marks: 10,
          color: ColorPalette.ratingExcellent,
          icon: Icons.star,
        ),
        RatingOption(
          id: 'rating-satisfactory',
          label: 'Satisfactory',
          labelMalayalam: 'ന്യായമായ',
          marks: 5,
          color: ColorPalette.ratingSatisfactory,
          icon: Icons.check,
        ),
        RatingOption(
          id: 'rating-needs-improvement',
          label: 'Needs Improvement',
          labelMalayalam: 'മെച്ചപ്പെടുത്തൽ',
          marks: 2,
          color: ColorPalette.ratingNeedsImprovement,
          icon: Icons.warning,
        ),
        RatingOption(
          id: 'rating-not-done',
          label: 'Not Done',
          labelMalayalam: 'പൂർത്തിയാക്കിയിട്ടില്ല',
          marks: 0,
          color: ColorPalette.ratingNotDone,
          icon: Icons.close,
        ),
      ],
    );
  }
}

/// Compact inline rating selector (horizontal only)
class AlifInlineRatingSelector extends StatelessWidget {
  final String? selectedRatingId;
  final ValueChanged<String> onChanged;
  final bool isDisabled;
  final bool isMalayalam;

  const AlifInlineRatingSelector({
    super.key,
    this.selectedRatingId,
    required this.onChanged,
    this.isDisabled = false,
    this.isMalayalam = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactOption(
            id: 'rating-excellent',
            label: 'Excellent',
            icon: Icons.star,
            color: ColorPalette.ratingExcellent,
          ),
          SizedBox(width: SpacingScale.sm),
          _buildCompactOption(
            id: 'rating-satisfactory',
            label: 'Satisfactory',
            icon: Icons.check,
            color: ColorPalette.ratingSatisfactory,
          ),
          SizedBox(width: SpacingScale.sm),
          _buildCompactOption(
            id: 'rating-needs-improvement',
            label: 'Needs',
            icon: Icons.warning,
            color: ColorPalette.ratingNeedsImprovement,
          ),
          SizedBox(width: SpacingScale.sm),
          _buildCompactOption(
            id: 'rating-not-done',
            label: 'Not Done',
            icon: Icons.close,
            color: ColorPalette.ratingNotDone,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOption({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedRatingId == id;

    return GestureDetector(
      onTap: isDisabled ? null : () => onChanged(id),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color : ColorPalette.white,
          border: Border.all(
            color: isSelected ? color : ColorPalette.neutral300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SpacingScale.sm,
          vertical: SpacingScale.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? ColorPalette.white : color,
            ),
            SizedBox(width: SpacingScale.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? ColorPalette.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
