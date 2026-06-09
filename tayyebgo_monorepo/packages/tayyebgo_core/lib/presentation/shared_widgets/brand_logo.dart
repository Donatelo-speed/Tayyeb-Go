import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TayyebLogoPainter extends CustomPainter {
  final double progress;
  final bool dark;

  TayyebLogoPainter({this.progress = 1.0, this.dark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 * 0.92;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: r * progress),
        Radius.circular(28 * progress),
      ),
      bgPaint,
    );

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: r * progress),
        Radius.circular(28 * progress),
      ),
    );

    final w = size.width;
    final h = size.height;
    final sw = w * 0.016;
    final whitePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final leftX = w * 0.36;
    final rightX = w * 0.64;
    final topY = h * 0.22;
    final bottomY = h * 0.78;

    canvas.drawLine(Offset(leftX, bottomY), Offset(leftX, topY), whitePaint);
    canvas.drawLine(Offset(rightX, bottomY), Offset(rightX, topY), whitePaint);

    final tineWidth = (rightX - leftX) * 0.6;
    final tineCenterX = (leftX + rightX) / 2;
    canvas.drawLine(
      Offset(tineCenterX - tineWidth, topY),
      Offset(tineCenterX + tineWidth, topY),
      whitePaint..strokeWidth = sw * 0.85,
    );
    canvas.drawLine(
      Offset(tineCenterX - tineWidth * 0.7, topY + h * 0.13),
      Offset(tineCenterX + tineWidth * 0.7, topY + h * 0.13),
      whitePaint..strokeWidth = sw * 0.75,
    );

    canvas.drawLine(
      Offset(leftX - w * 0.1, topY + h * 0.28),
      Offset(rightX + w * 0.1, topY + h * 0.28),
      whitePaint..strokeWidth = sw * 0.9,
    );

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 * progress)
      ..style = PaintingStyle.fill;
    final dotR = w * 0.028;
    canvas.drawCircle(Offset(leftX + w * 0.028, topY - h * 0.06), dotR * progress, dotPaint);
    canvas.drawCircle(Offset(rightX - w * 0.028, topY - h * 0.06), dotR * progress, dotPaint);

    canvas.restore();

    if (progress > 0.35) {
      final ringProgress = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18 * ringProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 0.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: center, radius: r * 0.88 * progress),
          Radius.circular(24 * progress),
        ),
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TayyebLogoPainter old) =>
      old.progress != progress || old.dark != dark;
}

class AnimatedLogoMark extends StatefulWidget {
  final double size;
  final bool animate;
  final bool dark;

  const AnimatedLogoMark({
    super.key,
    this.size = 88,
    this.animate = true,
    this.dark = false,
  });

  @override
  State<AnimatedLogoMark> createState() => _AnimatedLogoMarkState();
}

class _AnimatedLogoMarkState extends State<AnimatedLogoMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    if (widget.animate) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: TayyebLogoPainter(
          progress: _anim.value,
          dark: widget.dark,
        ),
      ),
    );
  }
}

class BrandWordmark extends StatefulWidget {
  final double fontSize;
  final Color textColor;
  final bool animate;

  const BrandWordmark({
    super.key,
    this.fontSize = 28,
    this.textColor = AppColors.textPrimary,
    this.animate = true,
  });

  @override
  State<BrandWordmark> createState() => _BrandWordmarkState();
}

class _BrandWordmarkState extends State<BrandWordmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
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
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [AppColors.primary, AppColors.accent]).createShader(bounds),
              child: Text(
                'Tayyeb',
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0,
                  height: 1.1,
                ),
              ),
            ),
            Text(
              'GO',
              style: TextStyle(
                fontSize: widget.fontSize * 1.05,
                fontWeight: FontWeight.w300,
                color: widget.textColor.withValues(alpha: 0.7),
                letterSpacing: 0,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.background : LightAppColors.background;
    final surface = isDark ? AppColors.surface : LightAppColors.surface;
    final textPrimary = isDark ? AppColors.textPrimary : LightAppColors.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : LightAppColors.textMuted;
    final border = isDark ? AppColors.border : LightAppColors.border;

    return Scaffold(
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              background,
              isDark ? const Color(0xFF0F1713) : const Color(0xFFEAF3EF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(
                        markSize: 88,
                        fontSize: 28,
                        textColor: textPrimary,
                        dark: isDark,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon, size: 18, color: widget.accentColor),
                            const SizedBox(width: 8),
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 132,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: border,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final Color textColor;
  final bool animate;
  final bool dark;
  final double gap;

  const BrandLogo({
    super.key,
    this.markSize = 72,
    this.fontSize = 26,
    this.textColor = AppColors.textPrimary,
    this.animate = true,
    this.dark = false,
    this.gap = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedLogoMark(size: markSize, animate: animate, dark: dark),
        SizedBox(height: gap),
        BrandWordmark(
          fontSize: fontSize,
          textColor: textColor,
          animate: animate,
        ),
      ],
    );
  }
}
