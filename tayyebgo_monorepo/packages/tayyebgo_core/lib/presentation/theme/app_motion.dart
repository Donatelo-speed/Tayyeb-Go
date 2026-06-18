import 'package:flutter/material.dart';

/// TayyebGo motion system.
///
/// Consistent animation durations, curves, and utilities for premium micro-interactions.
/// All animations should respect [MediaQuery.disableAnimations] for accessibility.
abstract class AppMotion {
  // ══════════════════════════════════════════════════════════════════════════
  // DURATION SCALE
  // ══════════════════════════════════════════════════════════════════════════

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration lazy = Duration(milliseconds: 480);

  // ══════════════════════════════════════════════════════════════════════════
  // CURVE SCALE
  // ══════════════════════════════════════════════════════════════════════════

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve springBouncy = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.easeInCubic;

  // ══════════════════════════════════════════════════════════════════════════
  // SPECIALTY DURATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Duration for hero transitions between screens.
  static const Duration heroDuration = slow;

  /// Duration for page transitions.
  static const Duration pageTransition = medium;

  /// Duration for bottom sheet animations.
  static const Duration bottomSheet = medium;

  /// Duration for dialog animations.
  static const Duration dialog = medium;

  // ══════════════════════════════════════════════════════════════════════════
  // STAGGER SYSTEM
  // ══════════════════════════════════════════════════════════════════════════

  static const Duration staggerDelay = Duration(milliseconds: 60);
  static const int staggerCount = 8;

  // ══════════════════════════════════════════════════════════════════════════
  // ANIMATION TICKER DURATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration pulseDuration = Duration(milliseconds: 1200);
  static const Duration spinDuration = Duration(milliseconds: 1000);

  // ══════════════════════════════════════════════════════════════════════════
  // ACCESSIBILITY
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns true if animations should play (respects system accessibility settings).
  static bool shouldAnimate(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);

  /// Returns the appropriate duration considering accessibility settings.
  /// If animations are disabled, returns [Duration.zero].
  static Duration effectiveDuration(BuildContext context, Duration duration) =>
      shouldAnimate(context) ? duration : Duration.zero;

  /// Returns the appropriate curve considering accessibility settings.
  /// If animations are disabled, returns [Curves.linear].
  static Curve effectiveCurve(BuildContext context, Curve curve) =>
      shouldAnimate(context) ? curve : Curves.linear;
}
