import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import 'app_button.dart';

/// TGErrorWidget — Error display with shake animation
class TGErrorWidget extends StatefulWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const TGErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  State<TGErrorWidget> createState() => _TGErrorWidgetState();
}

class _TGErrorWidgetState extends State<TGErrorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _ShakeCurve()),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shake = (_shakeAnimation.value * 8 - 4);
            return Transform.translate(
              offset: Offset(shake, 0),
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.glowError,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon ?? Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.title != null) ...[
                Text(
                  widget.title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 24),
                TGB.primary(
                  label: 'Try Again',
                  onPressed: widget.onRetry,
                  isExpanded: false,
                  width: 160,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShakeCurve extends Curve {
  @override
  double transformInternal(double t) {
    if (t < 0.2) return t * 5 * 0.3;
    if (t < 0.4) return 0.3 - (t - 0.2) * 5 * 0.3;
    if (t < 0.6) return (t - 0.4) * 5 * 0.15;
    if (t < 0.8) return 0.15 - (t - 0.6) * 5 * 0.15;
    return 0;
  }
}

// Backward compatibility alias
typedef AppErrorWidget = TGErrorWidget;
