import 'package:flutter/material.dart';

/// Avatar widget for user profile pictures
class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final Color? backgroundColor;
  final double size;

  const Avatar({
    this.imageUrl,
    this.initials,
    this.backgroundColor,
    this.size = 40,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement avatar widget
    return const Text('Avatar');
  }
}
