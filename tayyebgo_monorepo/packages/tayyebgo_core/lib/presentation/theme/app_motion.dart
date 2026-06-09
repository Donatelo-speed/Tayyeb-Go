import 'package:flutter/material.dart';

abstract class AppMotion {
  // ── Durations ──
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration lazy = Duration(milliseconds: 480);

  // ── Curves ──
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve springSoft = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve bounce = Curves.bounceOut;

  // ── Stagger ──
  static const Duration staggerDelay = Duration(milliseconds: 60);
  static const int staggerCount = 8;

  // ── Animation Ticker Durations ──
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration pulseDuration = Duration(milliseconds: 1200);
  static const Duration spinDuration = Duration(milliseconds: 1000);
}
