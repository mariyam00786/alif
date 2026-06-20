import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// 1-5 star rating control for activity performance
class ActivityRatingControl extends StatefulWidget {
  final int initialRating;
  final Function(int) onChanged;
  final bool readOnly;
  final double size;

  const ActivityRatingControl({
    this.initialRating = 0,
    required this.onChanged,
    this.readOnly = false,
    this.size = 40,
    Key? key,
  }) : super(key: key);

  @override
  State<ActivityRatingControl> createState() => _ActivityRatingControlState();
}

class _ActivityRatingControlState extends State<ActivityRatingControl> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = rating <= _rating;

        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() => _rating = rating);
                  widget.onChanged(rating);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isSelected ? Icons.star : Icons.star_outline,
              color: isSelected ? AppColors.getRatingColor(rating) : AppColors.grey300,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}
