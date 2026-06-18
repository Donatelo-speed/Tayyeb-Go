import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

/// TayyebGo spacing system.
///
/// 8pt grid-based spacing scale with EdgeInsets presets and responsive helpers.
/// All radius tokens live exclusively in [AppRadius] — not here.
abstract class AppSpacing {
  // ══════════════════════════════════════════════════════════════════════════
  // SPACING SCALE (8pt grid)
  // ══════════════════════════════════════════════════════════════════════════

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ══════════════════════════════════════════════════════════════════════════
  // EDGE INSETS PRESETS
  // ══════════════════════════════════════════════════════════════════════════

  static const EdgeInsets paddingXs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingSm = EdgeInsets.all(xs);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xxs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xxs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  // ══════════════════════════════════════════════════════════════════════════
  // RADIUS TOKENS
  // ══════════════════════════════════════════════════════════════════════════

  static const double radiusSm = 8;
  static const double radiusMd = 12;

  // Common screen-level padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingHorizontal = EdgeInsets.symmetric(horizontal: md);

  // ══════════════════════════════════════════════════════════════════════════
  // RESPONSIVE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns a responsive value based on current breakpoint.
  ///
  /// Example:
  /// ```dart
  /// double horizontalMargin = AppSpacing.responsivePadding(context);
  /// // Returns: 16 on mobile, 24 on tablet, 32 on desktop
  /// ```
  static double responsivePadding(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) return xl;
    if (AppBreakpoints.isTablet(context)) return lg;
    return md;
  }

  /// Returns responsive EdgeInsets with horizontal padding based on breakpoint.
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: responsivePadding(context));
  }

  /// Returns responsive value for any set of breakpoints.
  static double responsive(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (AppBreakpoints.isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (AppBreakpoints.isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Returns true if the current orientation is landscape.
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Returns true if the current orientation is portrait.
  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;
}
