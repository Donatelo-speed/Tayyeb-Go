import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FadeSlideIn — Fade + slide from any direction
/// ═══════════════════════════════════════════════════════════════════════════
enum SlideDirection { top, bottom, left, right }

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration? duration;
  final Curve curve;
  final double offset;
  final VoidCallback? onComplete;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.direction = SlideDirection.bottom,
    this.duration,
    this.curve = PremiumTheme.easeOut,
    this.offset = 24,
    this.onComplete,
  });

  const FadeSlideIn.fromTop({
    super.key,
    required this.child,
    this.duration,
    this.curve = PremiumTheme.easeOut,
    this.offset = 24,
    this.onComplete,
  }) : direction = SlideDirection.top;

  const FadeSlideIn.fromBottom({
    super.key,
    required this.child,
    this.duration,
    this.curve = PremiumTheme.easeOut,
    this.offset = 24,
    this.onComplete,
  }) : direction = SlideDirection.bottom;

  const FadeSlideIn.fromLeft({
    super.key,
    required this.child,
    this.duration,
    this.curve = PremiumTheme.easeOut,
    this.offset = 24,
    this.onComplete,
  }) : direction = SlideDirection.left;

  const FadeSlideIn.fromRight({
    super.key,
    required this.child,
    this.duration,
    this.curve = PremiumTheme.easeOut,
    this.offset = 24,
    this.onComplete,
  }) : direction = SlideDirection.right;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? PremiumTheme.durationMedium,
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    Offset begin;
    switch (widget.direction) {
      case SlideDirection.top:
        begin = Offset(0, -widget.offset / 100);
        break;
      case SlideDirection.bottom:
        begin = Offset(0, widget.offset / 100);
        break;
      case SlideDirection.left:
        begin = Offset(-widget.offset / 100, 0);
        break;
      case SlideDirection.right:
        begin = Offset(widget.offset / 100, 0);
        break;
    }

    _slideAnim = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _controller.forward().then((_) => widget.onComplete?.call());
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
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: _slideAnim.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ScaleIn — Scale pop-in effect
/// ═══════════════════════════════════════════════════════════════════════════
class ScaleIn extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Curve curve;
  final double initialScale;

  const ScaleIn({
    super.key,
    required this.child,
    this.duration,
    this.curve = PremiumTheme.springSoft,
    this.initialScale = 0.8,
  });

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? PremiumTheme.durationMedium,
    );

    _scaleAnim = Tween<double>(
      begin: widget.initialScale,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _controller.forward();
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
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// StaggeredAnimation — List item stagger entrance
/// ═══════════════════════════════════════════════════════════════════════════
class StaggeredAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration? staggerDelay;
  final Duration? duration;
  final Curve curve;

  const StaggeredAnimation({
    super.key,
    required this.index,
    required this.child,
    this.staggerDelay,
    this.duration,
    this.curve = PremiumTheme.easeOut,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final delay = widget.staggerDelay ??
        Duration(milliseconds: 60 * widget.index.clamp(0, 10));

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? PremiumTheme.durationMedium,
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
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
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: _slideAnim.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ShimmerLoading — Skeleton placeholder with animated gradient
/// ═══════════════════════════════════════════════════════════════════════════
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.duration,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
    } else if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final dark = PremiumTheme.isDark(context);
    final base = widget.baseColor ??
        (dark ? PremiumTheme.darkSurfaceAlt : PremiumTheme.lightSurfaceAlt);
    final highlight = widget.highlightColor ??
        base.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, -0.5),
              end: const Alignment(1.0, 0.5),
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (2 * slidePercent - 1), 0, 0);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PulseAnimation — Breathing pulse effect
/// ═══════════════════════════════════════════════════════════════════════════
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final Curve curve;

  const PulseAnimation({
    super.key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = PremiumTheme.durationLazy,
    this.curve = PremiumTheme.easeInOut,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
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
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CounterAnimation — Number counting up effect
/// ═══════════════════════════════════════════════════════════════════════════
class CounterAnimation extends StatefulWidget {
  final int endValue;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const CounterAnimation({
    super.key,
    required this.endValue,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<CounterAnimation> createState() => _CounterAnimationState();
}

class _CounterAnimationState extends State<CounterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _anim = Tween<double>(
      begin: 0,
      end: widget.endValue.toDouble(),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.addListener(() {
      setState(() => _current = _anim.value.round());
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(CounterAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endValue != widget.endValue) {
      _anim = Tween<double>(
        begin: oldWidget.endValue.toDouble(),
        end: widget.endValue.toDouble(),
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
    final defaultStyle = GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w800,
    );

    return Text(
      '${widget.prefix}$_current${widget.suffix}',
      style: widget.style ?? defaultStyle,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ParallaxScroll — Scroll-based parallax effect
/// ═══════════════════════════════════════════════════════════════════════════
class ParallaxScroll extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;
  final double rate;
  final bool reverse;

  const ParallaxScroll({
    super.key,
    required this.scrollController,
    required this.child,
    this.rate = 0.5,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final offset = scrollController.offset * rate * (reverse ? -1 : 1);
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
    );
  }
}

// Flutter's AnimatedBuilder is used directly — no typedef needed.

// ═══════════════════════════════════════════════════════════════════════════
// STAGGERED LIST BUILDER — utility for staggering lists
// ═══════════════════════════════════════════════════════════════════════════

class StaggeredList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;

  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.animationDuration = PremiumTheme.durationMedium,
    this.curve = PremiumTheme.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return StaggeredAnimation(
          index: index,
          staggerDelay: staggerDelay,
          duration: animationDuration,
          curve: curve,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
