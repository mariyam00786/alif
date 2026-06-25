import 'package:flutter/material.dart';

class AlifLogo extends StatelessWidget {
  const AlifLogo({super.key, this.height = 72, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final iconSize = height * 0.54;
    return Container(
      height: height,
      width: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A9A96), Color(0xFF0F766E)],
        ),
        border: Border.all(color: const Color(0xFF8ED1CC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.school_rounded, color: Colors.white, size: iconSize),
    );
  }
}
