import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';

/// TGBadge = TayyebGoBadge — Status, count, and role badges
enum TGBadgeVariant { status, count, role, category }

class TGBadge extends StatelessWidget {
  final String label;
  final TGBadgeVariant variant;
  final Color? color;
  final Color? backgroundColor;
  final bool small;

  const TGBadge({
    super.key,
    required this.label,
    this.variant = TGBadgeVariant.status,
    this.color,
    this.backgroundColor,
    this.small = false,
  });

  // ── Named constructors ──
  const TGBadge.active({super.key})
      : label = 'Active',
        variant = TGBadgeVariant.status,
        color = AppColors.success,
        backgroundColor = AppColors.successSoft,
        small = false;

  const TGBadge.inactive({super.key})
      : label = 'Inactive',
        variant = TGBadgeVariant.status,
        color = AppColors.textMuted,
        backgroundColor = AppColors.surfaceAlt,
        small = false;

  const TGBadge.pending({super.key})
      : label = 'Pending',
        variant = TGBadgeVariant.status,
        color = AppColors.warning,
        backgroundColor = AppColors.warningSoft,
        small = false;

  const TGBadge.error({super.key})
      : label = 'Error',
        variant = TGBadgeVariant.status,
        color = AppColors.error,
        backgroundColor = AppColors.errorSoft,
        small = false;

  const TGBadge.count({super.key, required int count})
      : label = count > 99 ? '99+' : '$count',
        variant = TGBadgeVariant.count,
        color = Colors.white,
        backgroundColor = AppColors.error,
        small = false;

  const TGBadge.role({super.key, required this.label})
      : variant = TGBadgeVariant.role,
        color = AppColors.primary,
        backgroundColor = AppColors.primarySoft,
        small = false;

  const TGBadge.category({super.key, required this.label})
      : variant = TGBadgeVariant.category,
        color = AppColors.textSecondary,
        backgroundColor = AppColors.surfaceAlt,
        small = false;

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 10.0 : 12.0;
    final horizontalPadding = small ? 6.0 : 10.0;
    final verticalPadding = small ? 2.0 : 4.0;

    if (variant == TGBadgeVariant.count) {
      final isSingleDigit = label.length <= 2;
      return Container(
        width: isSingleDigit ? 20 : null,
        height: 20,
        padding: EdgeInsets.symmetric(
          horizontal: isSingleDigit ? 0 : 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.error,
          borderRadius: AppRadius.brBadge,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color ?? Colors.white,
              height: 1,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceAlt,
        borderRadius: AppRadius.brChip,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textSecondary,
          height: 1.3,
        ),
      ),
    );
  }
}

// Dot indicator for online status
class TGDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool pulse;

  const TGDot({
    super.key,
    this.color = AppColors.success,
    this.size = 8,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!pulse) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return _PulsingDot(color: color, size: size);
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4 * (1 - _controller.value)),
                blurRadius: 8 * (1 - _controller.value),
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
