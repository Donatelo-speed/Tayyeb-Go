import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppAnimations {
  AppAnimations._();

  static Widget fadeInSlideUp({required Widget child, required Animation<double> animation, double delay = 0.0}) {
    final delayed = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: delayed,
      builder: (context, _) => Opacity(
        opacity: delayed.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - delayed.value)),
          child: child,
        ),
      ),
    );
  }

  static Widget staggeredList({required int index, required Animation<double> animation, required Widget child}) {
    final delay = (index * 0.08).clamp(0.0, 0.5);
    return fadeInSlideUp(child: child, animation: animation, delay: delay);
  }

  static Widget scaleIn({required Widget child, required Animation<double> animation, double delay = 0.0}) {
    final delayed = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.elasticOut),
    );
    return AnimatedBuilder(
      animation: delayed,
      builder: (context, _) => Transform.scale(
        scale: delayed.value,
        child: child,
      ),
    );
  }

  static Widget pulseScale({required Widget child, required Animation<double> animation}) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform.scale(
        scale: 1.0 + 0.03 * (animation.value - 0.5),
        child: child,
      ),
    );
  }
}

class StaggeredListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration duration;
  final Duration staggerDuration;

  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDuration = const Duration(milliseconds: 80),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return ListView.builder(
          itemCount: itemCount,
          itemBuilder: (ctx, i) {
            final delay = (i * 0.08).clamp(0.0, 0.5);
            final progress = ((value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - progress)),
                child: itemBuilder(ctx, i),
              ),
            );
          },
        );
      },
    );
  }
}

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: LinearGradient(
            begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
            end: Alignment(-0.5 + 2.0 * _ctrl.value, 0),
            colors: const [
              Color(0xFF1E1E2E),
              Color(0xFF2A2A3E),
              Color(0xFF1E1E2E),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSlideTransitionPage extends CustomTransitionPage<void> {
  AppSlideTransitionPage({required super.child})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}
