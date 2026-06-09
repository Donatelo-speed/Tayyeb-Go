import 'package:flutter/material.dart';

/// StaggerController — Drives a staggered list animation from parent
class StaggerController {
  final TickerProvider vsync;
  late final AnimationController controller;
  final int itemCount;
  final Duration duration;
  final Duration staggerDuration;

  StaggerController({
    required this.vsync,
    this.itemCount = 10,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDuration = const Duration(milliseconds: 80),
  }) {
    controller = AnimationController(vsync: vsync, duration: duration);
  }

  /// Returns the animated opacity for item at [index]
  double opacity(int index) {
    final start = (index * staggerDuration.inMilliseconds) /
        duration.inMilliseconds;
    final end = ((index + 1) * staggerDuration.inMilliseconds) /
        duration.inMilliseconds;
    final interval = Interval(
      start.clamp(0.0, 1.0),
      end.clamp(0.0, 1.0),
      curve: Curves.easeOut,
    );
    return interval.transform(controller.value);
  }

  /// Returns the translated Y offset for item at [index]
  double translateY(int index, {double distance = 24.0}) {
    final start = (index * staggerDuration.inMilliseconds) /
        duration.inMilliseconds;
    final end = ((index + 1) * staggerDuration.inMilliseconds) /
        duration.inMilliseconds;
    final interval = Interval(
      start.clamp(0.0, 1.0),
      end.clamp(0.0, 1.0),
      curve: Curves.easeOut,
    );
    return distance * (1 - interval.transform(controller.value));
  }

  void forward() => controller.forward();
  void reverse() => controller.reverse();
  void reset() => controller.reset();
  void dispose() => controller.dispose();
}

/// StaggeredAnimatedList — Wraps children in a staggered fade+slide animation
class StaggeredAnimatedList extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDuration;
  final double offset;

  const StaggeredAnimatedList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDuration = const Duration(milliseconds: 80),
    this.offset = 24.0,
  });

  @override
  State<StaggeredAnimatedList> createState() => _StaggeredAnimatedListState();
}

class _StaggeredAnimatedListState extends State<StaggeredAnimatedList>
    with SingleTickerProviderStateMixin {
  late final StaggerController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = StaggerController(
      vsync: this,
      itemCount: widget.children.length,
      duration: widget.duration,
      staggerDuration: widget.staggerDuration,
    );
    _stagger.forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _stagger.controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.children.length, (i) {
            return Opacity(
              opacity: _stagger.opacity(i),
              child: Transform.translate(
                offset: Offset(0, _stagger.translateY(i, distance: widget.offset)),
                child: widget.children[i],
              ),
            );
          }),
        );
      },
    );
  }
}
