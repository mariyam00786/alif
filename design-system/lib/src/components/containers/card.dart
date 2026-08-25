import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Card container widget with customizable padding and elevation
class Card extends StatelessWidget {
  final Widget child;
  final double padding;
  final double elevation;
  final VoidCallback? onTap;
  final bool isSelectable;
  final bool isSelected;
  final Color? backgroundColor;

  const Card({
    required this.child,
    this.padding = AppSpacing.base,
    this.elevation = 1,
    this.onTap,
    this.isSelectable = false,
    this.isSelected = false,
    this.backgroundColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.white,
      elevation: elevation,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelectable && isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
