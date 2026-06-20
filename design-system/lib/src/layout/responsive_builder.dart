import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  static const double xs = 0;
  static const double sm = 480;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1440;
  static const double xxl = 1920;
}

/// Device size categories
enum DeviceSize { mobile, tablet, desktop, wide }

/// Responsive builder widget for building responsive layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext) mobile;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;
  final Widget Function(BuildContext)? wide;

  const ResponsiveBuilder({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= Breakpoints.xxl) {
      return (wide ?? desktop ?? tablet ?? mobile)(context);
    } else if (width >= Breakpoints.xl) {
      return (desktop ?? tablet ?? mobile)(context);
    } else if (width >= Breakpoints.lg) {
      return (desktop ?? tablet ?? mobile)(context);
    } else if (width >= Breakpoints.md) {
      return (tablet ?? mobile)(context);
    } else {
      return mobile(context);
    }
  }

  /// Get current device size
  static DeviceSize getDeviceSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= Breakpoints.xxl) return DeviceSize.wide;
    if (width >= Breakpoints.xl) return DeviceSize.desktop;
    if (width >= Breakpoints.lg) return DeviceSize.desktop;
    if (width >= Breakpoints.md) return DeviceSize.tablet;
    return DeviceSize.mobile;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.md;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.md && width < Breakpoints.lg;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.lg;
  }
}
