import 'package:flutter/material.dart';
import '../../presentation/theme/app_colors.dart';

/// PulseAnimation — A pulsing glow animation
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.duration = const Duration(milliseconds: 1200),
    this.minScale = 1.0,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.minScale +
              (_controller.value * (widget.maxScale - widget.minScale)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// PulseGlow — A pulsing glow behind a widget
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const PulseGlow({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.duration = const Duration(milliseconds: 1500),
    this.minOpacity = 0.0,
    this.maxOpacity = 0.3,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity =
            widget.minOpacity + (_controller.value * (widget.maxOpacity - widget.minOpacity));
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: opacity),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
