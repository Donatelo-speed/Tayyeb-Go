import 'package:flutter/material.dart';
import '../design_system/app_motion.dart';

class StaggerItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final double offset;
  const StaggerItem({super.key, required this.index, required this.child, this.delay = AppMotion.stagger, this.offset = 20});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300) + delay * index,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class FadeInItem extends StatelessWidget {
  final Widget child;
  final Duration delay;
  const FadeInItem({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250) + delay,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
