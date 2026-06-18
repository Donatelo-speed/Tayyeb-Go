import 'package:flutter/material.dart';

/// TayyebGo responsive breakpoint system.
///
/// Defines breakpoints and provides context-based helpers for responsive layouts.
abstract class AppBreakpoints {
  // ══════════════════════════════════════════════════════════════════════════
  // BREAKPOINT VALUES
  // ══════════════════════════════════════════════════════════════════════════

  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1280;
  static const double wide = 1440;

  // ══════════════════════════════════════════════════════════════════════════
  // CONTEXT-BASED HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  // ══════════════════════════════════════════════════════════════════════════
  // ORIENTATION HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  // ══════════════════════════════════════════════════════════════════════════
  // WIDTH-BASED HELPERS (backward compat)
  // ══════════════════════════════════════════════════════════════════════════

  static bool isMobileWidth(double width) => width < mobile;
  static bool isTabletWidth(double width) => width >= mobile && width < desktop;
  static bool isDesktopWidth(double width) => width >= desktop;
  static bool isWideWidth(double width) => width >= wide;

  // ══════════════════════════════════════════════════════════════════════════
  // RESPONSIVE VALUE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns a value based on current breakpoint.
  static double responsive(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Returns responsive column count for grid layouts.
  static int responsiveColumns(BuildContext context) {
    if (isWide(context)) return 4;
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  /// Returns max content width for centered layouts.
  static double maxContentWidth(BuildContext context) {
    if (isWide(context)) return 1200;
    if (isDesktop(context)) return 1024;
    if (isTablet(context)) return 768;
    return double.infinity;
  }
}
