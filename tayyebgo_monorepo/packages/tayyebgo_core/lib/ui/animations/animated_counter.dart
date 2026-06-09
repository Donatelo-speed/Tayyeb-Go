import 'package:flutter/material.dart';

/// AnimatedCounter — A number that animates between values
class AnimatedCounter extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  num _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _currentValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        _currentValue = _animation.value;
        final display = widget.decimals > 0
            ? _animation.value.toStringAsFixed(widget.decimals)
            : _animation.value.round().toString();
        return Text(
          '${widget.prefix}$display${widget.suffix}',
          style: widget.style ?? const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
