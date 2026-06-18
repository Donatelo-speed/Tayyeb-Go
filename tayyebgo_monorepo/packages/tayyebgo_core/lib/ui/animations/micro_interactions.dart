import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../presentation/theme/app_motion.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';

/// Button press scale with optional haptic feedback.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enableHaptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.enableHaptic = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      reverseDuration: AppMotion.normal,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          if (widget.enableHaptic) HapticFeedback.lightImpact();
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enableHaptic) HapticFeedback.lightImpact();
          _controller.forward();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _animation, child: widget.child),
      ),
    );
  }
}

/// Card with elevated shadow on hover (web) or press (mobile).
class HoverElevation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;

  const HoverElevation({
    super.key,
    required this.child,
    this.onTap,
    this.elevation = 8.0,
  });

  @override
  State<HoverElevation> createState() => _HoverElevationState();
}

class _HoverElevationState extends State<HoverElevation> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.easeOut,
          transform: Matrix4.identity()..translate(0.0, _hovering ? -2.0 : 0.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: _hovering ? 0.2 : 0.08),
                blurRadius: _hovering ? widget.elevation * 2 : widget.elevation,
                offset: Offset(0, _hovering ? 4 : 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Quantity stepper with animated counter.
class AnimatedQuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const AnimatedQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brCard,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PressScale(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value > min ? AppColors.primary : AppColors.border,
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(
                Icons.remove_rounded,
                color: value > min ? Colors.white : AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          PressScale(
            onTap: value < max ? () => onChanged(value + 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value < max ? AppColors.primary : AppColors.border,
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(
                Icons.add_rounded,
                color: value < max ? Colors.white : AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
