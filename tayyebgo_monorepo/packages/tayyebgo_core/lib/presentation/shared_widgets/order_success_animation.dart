import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A full-screen overlay that shows confetti particles + animated checkmark
/// after a successful order placement.
class OrderSuccessAnimation extends StatefulWidget {
  final String orderId;
  final VoidCallback onDismiss;

  const OrderSuccessAnimation({
    super.key,
    required this.orderId,
    required this.onDismiss,
  });

  @override
  State<OrderSuccessAnimation> createState() => _OrderSuccessAnimationState();
}

class _OrderSuccessAnimationState extends State<OrderSuccessAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _textCtrl;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    // Confetti
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    final rng = Random();
    _particles = List.generate(60, (_) => _ConfettiParticle(rng));

    // Checkmark scale-in
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // Text fade-in
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _confettiCtrl.forward();
    _checkCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textCtrl.forward();
    });

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _checkCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Stack(
          children: [
            // Confetti layer
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiCtrl.value,
                ),
              ),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark circle
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic)),
                      child: Column(
                        children: [
                          Text(
                            'Order Placed!',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your order is being prepared',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tap to continue',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single confetti particle with random properties.
class _ConfettiParticle {
  final double x; // 0..1 normalized
  final double startY;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;

  _ConfettiParticle(Random rng)
      : x = rng.nextDouble(),
        startY = -0.05 - rng.nextDouble() * 0.1,
        speed = 0.3 + rng.nextDouble() * 0.5,
        rotation = rng.nextDouble() * 2 * pi,
        rotationSpeed = (rng.nextDouble() - 0.5) * 6,
        size = 4 + rng.nextDouble() * 6,
        color = [
          const Color(0xFFFF6B35),
          const Color(0xFF22C55E),
          const Color(0xFF3B82F6),
          const Color(0xFFFBBF24),
          const Color(0xFFEC4899),
          const Color(0xFF8B5CF6),
        ][rng.nextInt(6)];
}

/// Paints confetti particles falling with gravity.
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress;
      final x = p.x * size.width;
      final y = (p.startY + p.speed * t) * size.height;
      if (y < -20 || y > size.height + 20) continue;

      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);

      // Draw a small rectangle (confetti piece)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
