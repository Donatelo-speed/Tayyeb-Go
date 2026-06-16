import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';

/// TGProgress — Circular and linear progress indicators
class TGCircularProgress extends StatelessWidget {
  final double? size;
  final double? strokeWidth;
  final Color? color;
  final String? label;

  const TGCircularProgress({
    super.key,
    this.size,
    this.strokeWidth,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? AppColors.primary;

    if (label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 32,
            height: size ?? 32,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth ?? 3,
              color: progressColor,
              backgroundColor: isDark ? AppColors.surfaceAlt : const Color(0xFFF0F2F5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMuted : const Color(0xFF93A0AF),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 2.5,
        color: progressColor,
      ),
    );
  }
}

/// TGLinearProgress — Themed linear progress bar
class TGLinearProgress extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final String? label;
  final String? valueLabel;

  const TGLinearProgress({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.backgroundColor,
    this.label,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ?? (isDark ? AppColors.surfaceAlt : const Color(0xFFF0F2F5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || valueLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondary : const Color(0xFF6B7686),
                    ),
                  ),
                if (valueLabel != null)
                  Text(
                    valueLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimary : const Color(0xFF151922),
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.brBadge,
          ),
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: AppRadius.brBadge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
