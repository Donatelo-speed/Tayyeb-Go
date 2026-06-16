import 'package:flutter/material.dart';

/// Animated container that fades and slides in on build.
class AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;
  final double delay;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.15),
    this.curve = Curves.easeOutCubic,
    this.delay = 0,
  });

  @override
  State<AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
    
    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: widget.delay.toInt()), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Staggered list of children that animate in sequentially.
class AnimatedStagger extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDuration;
  final Duration fadeDuration;

  const AnimatedStagger({
    super.key,
    required this.children,
    this.staggerDuration = const Duration(milliseconds: 80),
    this.fadeDuration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedStagger> createState() => _AnimatedStaggerState();
}

class _AnimatedStaggerState extends State<AnimatedStagger>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.fadeDuration + widget.staggerDuration * widget.children.length,
    );
    _fadeAnims = [];
    _slideAnims = [];
    for (var i = 0; i < widget.children.length; i++) {
      final start = (widget.staggerDuration * i).inMilliseconds / _ctrl.duration!.inMilliseconds;
      final end = ((widget.fadeDuration + widget.staggerDuration * i).inMilliseconds /
              _ctrl.duration!.inMilliseconds)
          .clamp(0.0, 1.0);
      _fadeAnims.add(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
      _slideAnims.add(
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          FadeTransition(
            opacity: _fadeAnims[i],
            child: SlideTransition(
              position: _slideAnims[i],
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}

/// Scale-in animation for icons/images.
class AnimatedScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double beginScale;

  const AnimatedScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.beginScale = 0.5,
  });

  @override
  State<AnimatedScaleIn> createState() => _AnimatedScaleInState();
}

class _AnimatedScaleInState extends State<AnimatedScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: widget.beginScale, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Pulsing glow animation for buttons/indicators.
class AnimatedPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const AnimatedPulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minOpacity = 0.6,
    this.maxOpacity = 1.0,
  });

  @override
  State<AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _anim = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: widget.child,
    );
  }
}

/// Parallax scroll effect widget
class ParallaxWidget extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final double rate;
  final bool vertical;

  const ParallaxWidget({
    super.key,
    required this.child,
    required this.scrollController,
    this.rate = 0.5,
    this.vertical = true,
  });

  @override
  State<ParallaxWidget> createState() => _ParallaxWidgetState();
}

class _ParallaxWidgetState extends State<ParallaxWidget> {
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ParallaxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _offset = widget.scrollController.offset * widget.rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: widget.vertical ? Offset(0, -_offset) : Offset(-_offset, 0),
      child: widget.child,
    );
  }
}

/// Shimmer loading effect
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ?? (isDark ? const Color(0xFF1A2420) : const Color(0xFFEEF3F0));
    final highlightColor = widget.highlightColor ?? (isDark 
        ? const Color(0xFF243830).withValues(alpha: 0.5) 
        : const Color(0xFFD6E0DA));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Slide to reveal animation
class SlideToReveal extends StatefulWidget {
  final Widget child;
  final Widget revealedChild;
  final VoidCallback? onRevealed;
  final double threshold;

  const SlideToReveal({
    super.key,
    required this.child,
    required this.revealedChild,
    this.onRevealed,
    this.threshold = 0.7,
  });

  @override
  State<SlideToReveal> createState() => _SlideToRevealState();
}

class _SlideToRevealState extends State<SlideToReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragExtent = 0;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: widget.revealedChild,
        ),
        SlideTransition(
          position: _slideAnimation,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final width = context.size?.width ?? 1;
                setState(() {
                _dragExtent += -(details.primaryDelta ?? 0);
                final progress = (_dragExtent / width).clamp(0.0, 1.0);
                _controller.value = progress;
                
                if (progress > widget.threshold && !_isRevealed) {
                  _isRevealed = true;
                  widget.onRevealed?.call();
                }
              });
            },
            onHorizontalDragEnd: (details) {
              if (_controller.value < widget.threshold) {
                _controller.reverse();
                _dragExtent = 0;
                _isRevealed = false;
              } else {
                _controller.forward();
              }
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Animated tab indicator
class AnimatedTabIndicator extends StatefulWidget {
  final int selectedIndex;
  final int itemCount;
  final Color color;
  final double height;
  final double spacing;

  const AnimatedTabIndicator({
    super.key,
    required this.selectedIndex,
    required this.itemCount,
    this.color = const Color(0xFF00A676),
    this.height = 3,
    this.spacing = 24,
  });

  @override
  State<AnimatedTabIndicator> createState() => _AnimatedTabIndicatorState();
}

class _AnimatedTabIndicatorState extends State<AnimatedTabIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(AnimatedTabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
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
      builder: (context, child) {
        final lerp = _animation.value;
        final left = _previousIndex * widget.spacing + 
            (widget.selectedIndex - _previousIndex) * widget.spacing * lerp;
        
        return Positioned(
          bottom: 0,
          left: left,
          child: Container(
            width: widget.spacing * 0.6,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
          ),
        );
      },
    );
  }
}

/// Animated press scale widget
class AnimatedPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const AnimatedPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<AnimatedPressScale> createState() => _AnimatedPressScaleState();
}

class _AnimatedPressScaleState extends State<AnimatedPressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
