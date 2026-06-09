import 'package:flutter/material.dart';

/// SpringAnimation — A physics-based spring animation widget
class SpringAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double lowerBound;
  final double upperBound;
  final double stiffness;
  final double damping;
  final bool animateOnBuild;

  const SpringAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.lowerBound = 0.8,
    this.upperBound = 1.0,
    this.stiffness = 300.0,
    this.damping = 15.0,
    this.animateOnBuild = false,
  });

  @override
  State<SpringAnimation> createState() => _SpringAnimationState();
}

class _SpringAnimationState extends State<SpringAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: widget.lowerBound,
      upperBound: widget.upperBound,
      value: widget.upperBound,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    if (widget.animateOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bounce());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _bounce() {
    _controller.forward(from: widget.lowerBound);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(scale: _animation, child: widget.child),
    );
  }
}

/// TGPressScale — A press-to-scale widget (simpler than SpringAnimation)
class TGPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const TGPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<TGPressScale> createState() => _TGPressScaleState();
}

class _TGPressScaleState extends State<TGPressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _animation, child: widget.child),
    );
  }
}
