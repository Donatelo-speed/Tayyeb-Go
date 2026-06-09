import 'package:flutter/material.dart';

abstract class AppBreakpoints {
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1280;
  static const double wide = 1440;

  // ── Context-based helpers ──
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

  // ── Width-based helpers (backward compat) ──
  static bool isMobileWidth(double width) => width < mobile;
  static bool isTabletWidth(double width) => width >= mobile && width < desktop;
  static bool isDesktopWidth(double width) => width >= desktop;
  static bool isWideWidth(double width) => width >= wide;
}
