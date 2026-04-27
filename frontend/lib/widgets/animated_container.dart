import 'package:flutter/material.dart';

/// Custom animated container with multiple animation variants
class AnimatedOmniContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final AlignmentGeometry alignment;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;

  const AnimatedOmniContainer({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.margin,
    this.padding,
    this.color,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.gradient,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
        gradient: gradient,
      ),
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: onTap != null ? InkWell(onTap: onTap, child: child) : child,
    );
  }
}

/// Button with scale animation on press
class ScaleAnimatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scaleFactor;
  final Duration duration;

  const ScaleAnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(context),
      onTapUp: (_) => _onTapUp(context),
      onTapCancel: () => _onTapUp(context),
      onTap: onPressed,
      child: child,
    );
  }

  void _onTapDown(BuildContext context) {
    final renderObject = context.findRenderObject() as RenderBox?;
    if (renderObject != null) {
      final controller = AnimationController(
        vsync: _createTicker(context),
        duration: duration,
      );
      final animation = Tween<double>(begin: 1.0, end: scaleFactor).animate(controller);
      controller.forward();
      // We don't dispose the controller here as we want to reuse it
      // In a real app, you'd manage this better with a State widget
    }
  }

  void _onTapUp(BuildContext context) {
    final renderObject = context.findRenderObject() as RenderBox?;
    if (renderObject != null) {
      final controller = AnimationController(
        vsync: _createTicker(context),
        duration: duration,
      );
      final animation = Tween<double>(begin: scaleFactor, end: 1.0).animate(controller);
      controller.forward();
      // We don't dispose the controller here as we want to reuse it
      // In a real app, you'd manage this better with a State widget
    }
  }

  TickerProvider _createTicker(BuildContext context) {
    return TickerProvider.of(context);
  }
}

/// Fade in animation widget
class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double delay;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeIn,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}

/// Slide in animation widget
class SlideInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;
  final double delay;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.beginOffset = const Offset(0, 0.3),
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: beginOffset, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.translate(offset: value, child: child),
      child: child,
    );
  }
}

/// Scale in animation widget
class ScaleInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double delay;

  const ScaleInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: child,
    );
  }
}

/// Staggered animation for lists
class StaggeredAnimation extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;
  final Curve curve;
  final double delayBetweenItems;

  const StaggeredAnimation({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.delayBetweenItems = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        int index = entry.key;
        Widget child = entry.value;
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: duration,
            curve: curve,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: child,
          ),
        );
      }).toList(),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: const Shimmer(
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }
}