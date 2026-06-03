import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_names.dart';
import '../../presentation/shared_widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  final Duration displayDuration;
  final Widget Function()? nextBuilder;

  const SplashScreen({
    super.key,
    this.displayDuration = const Duration(milliseconds: 2600),
    this.nextBuilder,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _FloatingParticle {
  final double x, y, vx, vy, size, opacity, delay;
  _FloatingParticle({
    required this.x, required this.y, required this.vx,
    required this.vy, required this.size, required this.opacity,
    required this.delay,
  });
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _logoScale, _textFade, _bgShift;
  late AnimationController _particleCtrl;

  final _particles = List.generate(30, (_) {
    final rng = math.Random();
    return _FloatingParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      vx: (rng.nextDouble() - 0.5) * 0.4,
      vy: -0.15 - rng.nextDouble() * 0.3,
      size: 1.5 + rng.nextDouble() * 3.5,
      opacity: 0.08 + rng.nextDouble() * 0.22,
      delay: rng.nextDouble() * 1.5,
    );
  });

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _logoScale = CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.elasticOut,
    );
    _textFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    _bgShift = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    );

    _particleCtrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _mainCtrl.forward();

    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        context.go(Routes.login);
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _mainCtrl,
        builder: (_, _) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF0A0D14),
                  const Color(0xFF0F1629),
                  _bgShift.value,
                )!,
                Color.lerp(
                  const Color(0xFF141822),
                  const Color(0xFF1D4ED8),
                  _bgShift.value,
                )!,
                Color.lerp(
                  const Color(0xFF0F1629),
                  const Color(0xFF312E81),
                  _bgShift.value * 0.7,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, _) => CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3 * _logoScale.value),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const AnimatedLogoMark(size: 108, animate: false),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: _textFade.value,
                      child: Transform.translate(
                        offset: Offset(0, 35 * (1 - _textFade.value)),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (b) =>
                                  const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF1D4ED8)],
                                  ).createShader(b),
                              child: const Text(
                                'Tayyeb',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            Text(
                              'GO',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w100,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 56),
                    Opacity(
                      opacity: _textFade.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.5),
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final pTime = (progress + p.delay) % 1.0;
      final px = (p.x + p.vx * pTime) * size.width;
      final py = (p.y + p.vy * pTime) * size.height;
      final alpha = p.opacity * (1.0 - pTime).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
