import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadow.dart';
import '../theme/app_radius.dart';

enum LogoVariant { full, icon, text }

class TayyebGoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showShadow;
  final LogoVariant variant;
  final Axis direction;

  const TayyebGoLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.showShadow = true,
    this.variant = LogoVariant.full,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final text = _LogoWordmark(size: size);

    if (variant == LogoVariant.text) {
      return text;
    }

    final mark = TayyebGoBrandMark(size: size, showShadow: showShadow);

    if (!showText || variant == LogoVariant.icon) {
      return mark;
    }

    final gap = SizedBox(
      width: direction == Axis.horizontal ? size * 0.18 : 0,
      height: direction == Axis.vertical ? size * 0.14 : 0,
    );

    return direction == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: [mark, gap, text])
        : Column(mainAxisSize: MainAxisSize.min, children: [mark, gap, text]);
  }
}

class TayyebGoCompactLogo extends StatelessWidget {
  final double size;

  const TayyebGoCompactLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return TayyebGoBrandMark(size: size, showShadow: false);
  }
}

class TayyebGoAnimatedLogo extends StatefulWidget {
  final double size;

  const TayyebGoAnimatedLogo({super.key, this.size = 100});

  @override
  State<TayyebGoAnimatedLogo> createState() => _TayyebGoAnimatedLogoState();
}

class BrandLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final String? subtitle;

  const BrandLogo({
    super.key,
    this.markSize = 72,
    this.fontSize = 24,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TayyebGoLogo(size: markSize, showText: true),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondary
                  : LightAppColors.textSecondary,
              fontSize: fontSize * 0.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class BrandedSplashView extends StatefulWidget {
  final String label;
  final String tagline;
  final IconData icon;
  final Color accentColor;

  const BrandedSplashView({
    super.key,
    required this.label,
    required this.tagline,
    required this.icon,
    required this.accentColor,
  });

  @override
  State<BrandedSplashView> createState() => _BrandedSplashViewState();
}

class _BrandedSplashViewState extends State<BrandedSplashView>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _staggerCtrl;
  late final Animation<double> _glowPulse;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _badgeFade;
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();

    // Ambient glow pulse — infinite
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Staggered entrance — one-shot
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _wordmarkFade = CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    _taglineFade = CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
    ));

    _badgeFade = CurvedAnimation(
      parent: _staggerCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkAppBackground
              : AppGradients.lightAppBackground,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with glow
              SlideTransition(
                position: _logoSlide,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Ambient glow orb
                      AnimatedBuilder(
                        animation: _glowPulse,
                        builder: (context, _) {
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  widget.accentColor.withValues(alpha: _glowPulse.value * 0.35),
                                  widget.accentColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      TayyebGoAnimatedLogo(size: 104),
                      // Role badge
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: FadeTransition(
                          opacity: _badgeFade,
                          child: ScaleTransition(
                            scale: _badgeScale,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.accentColor,
                                    widget.accentColor.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: AppRadius.brMd,
                                border: Border.all(
                                  color: isDark ? AppColors.background : Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.accentColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(widget.icon, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Wordmark
              SlideTransition(
                position: _wordmarkSlide,
                child: FadeTransition(
                  opacity: _wordmarkFade,
                  child: _LogoWordmark(size: 104),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              SlideTransition(
                position: _taglineSlide,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    widget.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: isDark
                          ? AppColors.textSecondary
                          : LightAppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TayyebGoBrandMark extends StatelessWidget {
  final double size;
  final bool showShadow;

  const TayyebGoBrandMark({
    super.key,
    this.size = 64,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = math.max(8.0, size * 0.24);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow ? AppShadow.glowPrimary(Theme.of(context).brightness == Brightness.dark) : null,
      ),
      child: CustomPaint(
        painter: _BrandGlyphPainter(),
      ),
    );
  }
}

class _LogoWordmark extends StatelessWidget {
  final double size;

  const _LogoWordmark({required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppGradients.primaryGradientHorizontal.createShader(bounds),
      child: Text(
        'TayyebGo',
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _TayyebGoAnimatedLogoState extends State<TayyebGoAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _turn;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _turn = Tween<double>(begin: -0.03, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: RotationTransition(
        turns: _turn,
        child: ScaleTransition(
          scale: _scale,
          child: TayyebGoBrandMark(size: widget.size),
        ),
      ),
    );
  }
}

class _BrandGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final soft = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final route = Path()
      ..moveTo(s * 0.2, s * 0.68)
      ..cubicTo(s * 0.36, s * 0.55, s * 0.48, s * 0.82, s * 0.64, s * 0.66)
      ..cubicTo(s * 0.72, s * 0.58, s * 0.76, s * 0.5, s * 0.82, s * 0.44);
    canvas.drawPath(route, soft);

    final pin = Path()
      ..moveTo(s * 0.5, s * 0.17)
      ..cubicTo(s * 0.31, s * 0.17, s * 0.2, s * 0.31, s * 0.2, s * 0.45)
      ..cubicTo(s * 0.2, s * 0.63, s * 0.38, s * 0.72, s * 0.5, s * 0.86)
      ..cubicTo(s * 0.62, s * 0.72, s * 0.8, s * 0.63, s * 0.8, s * 0.45)
      ..cubicTo(s * 0.8, s * 0.31, s * 0.69, s * 0.17, s * 0.5, s * 0.17)
      ..close();
    canvas.drawPath(pin, white);

    final cut = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(s * 0.5, s * 0.43), s * 0.16, cut);

    final bite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final cloche = Path()
      ..moveTo(s * 0.4, s * 0.45)
      ..quadraticBezierTo(s * 0.5, s * 0.31, s * 0.6, s * 0.45)
      ..lineTo(s * 0.64, s * 0.45)
      ..quadraticBezierTo(s * 0.5, s * 0.25, s * 0.36, s * 0.45)
      ..close();
    canvas.drawPath(cloche, bite);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.35, s * 0.47, s * 0.3, s * 0.045),
        Radius.circular(s * 0.02),
      ),
      bite,
    );
    canvas.drawCircle(Offset(s * 0.5, s * 0.33), s * 0.025, bite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
