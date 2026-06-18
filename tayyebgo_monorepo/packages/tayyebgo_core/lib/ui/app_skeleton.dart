import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';

/// TGS = TayyebGoSkeleton — Shimmer loading placeholders
class TGS extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool circle;

  const TGS({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.brSm,
    this.circle = false,
  });

  // ── Named constructors ──
  const TGS.text({super.key, double? width})
      : width = width ?? double.infinity,
        height = 14,
        borderRadius = AppRadius.brSm,
        circle = false;

  const TGS.textMulti({super.key, int lines = 3})
      : width = double.infinity,
        height = 14,
        borderRadius = AppRadius.brSm,
        circle = false;

  const TGS.avatar({super.key, double size = 48})
      : width = size,
        height = size,
        borderRadius = AppRadius.brAvatar,
        circle = true;

  const TGS.card({super.key})
      : width = double.infinity,
        height = 120,
        borderRadius = AppRadius.brCard,
        circle = false;

  const TGS.image({super.key, double? width, double? height})
      : width = width ?? double.infinity,
        height = height ?? 180,
        borderRadius = AppRadius.brCard,
        circle = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: circle ? BorderRadius.circular(width) : borderRadius,
      ),
      child: _ShimmerEffect(isDark: isDark),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  final bool isDark;
  const _ShimmerEffect({required this.isDark});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.surfaceAlt;
    final highlightColor = widget.isDark
        ? AppColors.surfaceAlt.withValues(alpha: 0.5)
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Multi-line text skeleton
class TGSGroup extends StatelessWidget {
  final int lines;
  final double spacing;
  final List<double>? widths;

  const TGSGroup({
    super.key,
    this.lines = 3,
    this.spacing = 10,
    this.widths,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (i) {
        final w = widths != null && i < widths!.length
            ? widths![i]
            : (i == lines - 1 ? 0.6 : 1.0);
        return Padding(
          padding: EdgeInsets.only(bottom: i < lines - 1 ? spacing : 0),
          child: FractionallySizedBox(
            widthFactor: w,
            child: const TGS.text(),
          ),
        );
      }),
    );
  }
}
