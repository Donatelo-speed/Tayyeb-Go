import 'package:flutter/material.dart';

/// Shows a small circular item that flies from [start] to [end] with a curved
/// trajectory, then fades out. Use via [FlyToCartOverlay.show].
class FlyToCartAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Widget child;
  final VoidCallback? onComplete;

  const FlyToCartAnimation({
    super.key,
    required this.start,
    required this.end,
    required this.child,
    this.onComplete,
  });

  /// Convenience: shows the fly overlay on the current [Navigator]'s overlay.
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required Offset start,
    required Offset end,
    required Widget child,
    VoidCallback? onComplete,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final entry = OverlayEntry(
      builder: (_) => FlyToCartAnimation(
        start: start,
        end: end,
        child: child,
        onComplete: () {
          _currentEntry?.remove();
          _currentEntry = null;
          onComplete?.call();
        },
      ),
    );
    _currentEntry = entry;
    Overlay.of(context).insert(entry);
  }

  @override
  State<FlyToCartAnimation> createState() => _FlyToCartAnimationState();
}

class _FlyToCartAnimationState extends State<FlyToCartAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _position;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    // Curved path: arc upward then down to cart
    final tween = Tween<Offset>(begin: widget.start, end: widget.end);
    _position = tween.animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.8, curve: Curves.easeInOut),
    ));

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.3), weight: 70),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _ctrl.forward();
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
      builder: (_, __) {
        final pos = _position.value;
        return Positioned(
          left: pos.dx - 16,
          top: pos.dy - 16,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Wraps a child with a [GlobalKey] so the caller can read its position
/// for the fly animation.
class FlyToCartTarget extends StatefulWidget {
  final Widget child;
  final GlobalKey<FlyToCartTargetState> targetKey;

  const FlyToCartTarget({
    super.key,
    required this.child,
    required this.targetKey,
  });

  @override
  State<FlyToCartTarget> createState() => FlyToCartTargetState();
}

class FlyToCartTargetState extends State<FlyToCartTarget> {
  /// Returns the center of this widget in global coordinates.
  Offset getCenter() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A simple circular widget used as the "flying item" in the animation.
class FlyToCartDot extends StatelessWidget {
  final Color color;
  final double size;

  const FlyToCartDot({
    super.key,
    this.color = const Color(0xFFFF6B35),
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 16),
    );
  }
}
