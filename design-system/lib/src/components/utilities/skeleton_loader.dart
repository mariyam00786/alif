import 'package:flutter/material.dart';

/// Skeleton loader for loading states
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final bool isCircle;

  const SkeletonLoader({
    required this.width,
    required this.height,
    this.isCircle = false,
    Key? key,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement skeleton loader with animation
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle ? null : BorderRadius.circular(8),
      ),
    );
  }
}
