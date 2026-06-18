import 'package:flutter/material.dart';

/// TayyebGo border radius system.
///
/// Clean scale from xs (4) to full (999) with semantic aliases for components.
/// Cards use 12px (larger than buttons at 8px) for visual hierarchy.
abstract class AppRadius {
  // ══════════════════════════════════════════════════════════════════════════
  // RADIUS SCALE
  // ══════════════════════════════════════════════════════════════════════════

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 20;
  static const double full = 999;

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS CONSTANTS
  // ══════════════════════════════════════════════════════════════════════════

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius brXxxl = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC RADIUS ALIASES
  // ══════════════════════════════════════════════════════════════════════════

  /// Cards use xl (12px) — visually distinct from buttons.
  static const BorderRadius brCard = BorderRadius.all(Radius.circular(xl));

  /// Buttons use md (8px) — tighter, more compact.
  static const BorderRadius brButton = BorderRadius.all(Radius.circular(md));

  /// Input fields use sm (6px) — subtle rounding.
  static const BorderRadius brInput = BorderRadius.all(Radius.circular(sm));

  /// Chips use full (pill shape).
  static const BorderRadius brChip = BorderRadius.all(Radius.circular(full));

  /// Avatars use full (circle).
  static const BorderRadius brAvatar = BorderRadius.all(Radius.circular(full));

  /// Dialogs use xxxl (20px) — large, prominent rounding.
  static const BorderRadius brDialog = BorderRadius.all(Radius.circular(xxxl));

  /// Bottom sheets use top-only xxxl (20px).
  static const BorderRadius brBottomSheet = BorderRadius.vertical(
    top: Radius.circular(xxxl),
  );

  /// Badges use full (pill shape).
  static const BorderRadius brBadge = BorderRadius.all(Radius.circular(full));

  // ══════════════════════════════════════════════════════════════════════════
  // ASYMMETRIC RADIUS (for chat bubbles, tooltips, etc.)
  // ══════════════════════════════════════════════════════════════════════════

  static BorderRadius brTopOnly(double radius) => BorderRadius.vertical(
        top: Radius.circular(radius),
      );

  static BorderRadius brBottomOnly(double radius) => BorderRadius.vertical(
        bottom: Radius.circular(radius),
      );

  static BorderRadius brLeftOnly(double radius) => BorderRadius.horizontal(
        left: Radius.circular(radius),
      );

  static BorderRadius brRightOnly(double radius) => BorderRadius.horizontal(
        right: Radius.circular(radius),
      );
}
