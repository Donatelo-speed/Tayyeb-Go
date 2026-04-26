import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticUtil {
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  static void vibrate() {
    HapticFeedback.vibrate();
  }

  static void success() {
    HapticFeedback.mediumImpact();
  }

  static void error() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }
}

class AnimationUtil {
  static const Curve defaultCurve = Curves.easeInOut;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static Widget fadeIn(Widget child, {Duration duration = normal}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: defaultCurve,
      builder: (context, value, _) => Opacity(opacity: value, child: child),
    );
  }

  static Widget slideUp(Widget child, {Duration duration = normal, double offset = 20}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: defaultCurve,
      builder: (context, value, _) => Transform.translate(offset: Offset(0, value), child: child),
    );
  }

  static Widget scaleIn(Widget child, {Duration duration = normal}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: duration,
      curve: defaultCurve,
      builder: (context, value, _) => Transform.scale(scale: value, child: child),
    );
  }
}