import 'package:flutter/material.dart';

class AlifLogo extends StatelessWidget {
  const AlifLogo({super.key, this.height = 72, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final size = height;
    final radius = size * 0.22;

    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.22),
            const Color(0xFFFFA000).withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.30), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius * 0.72),
          color: const Color(0xFF102A16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.16,
              right: size * 0.16,
              child: Container(
                width: size * 0.14,
                height: size * 0.14,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA000),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Icon(
              Icons.auto_stories,
              color: Colors.white,
              size: size * 0.36,
            ),
            Positioned(
              bottom: size * 0.14,
              child: Text(
                'ALIF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
