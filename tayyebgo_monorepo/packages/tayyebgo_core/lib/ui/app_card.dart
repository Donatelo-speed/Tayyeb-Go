import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';

enum TGCVariant { surface, elevated, outlined, glass }

class TGC extends StatelessWidget {
  final Widget child;
  final TGCVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const TGC({
    super.key,
    required this.child,
    this.variant = TGCVariant.surface,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? _getBackgroundColor(isDark);
    
    Widget card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: _getDecoration(isDark, bgColor),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  Color _getBackgroundColor(bool isDark) {
    switch (variant) {
      case TGCVariant.surface:
        return isDark ? AppColors.surface : Colors.white;
      case TGCVariant.elevated:
        return isDark ? AppColors.surfaceElevated : Colors.white;
      case TGCVariant.outlined:
        return Colors.transparent;
      case TGCVariant.glass:
        return isDark 
            ? AppColors.glassSurface 
            : Colors.white.withValues(alpha: 0.7);
    }
  }

  BoxDecoration _getDecoration(bool isDark, Color bgColor) {
    final borderColor = isDark ? AppColors.border : const Color(0xFFDDE7E2);
    
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: variant == TGCVariant.outlined || variant == TGCVariant.glass
          ? Border.all(
              color: borderColor.withValues(alpha: variant == TGCVariant.glass ? 0.3 : 0.6),
              width: 1,
            )
          : null,
      boxShadow: variant == TGCVariant.elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
          : variant == TGCVariant.glass
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
    );
  }
}

/// KPI stat card
class TGCKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? subtitle;

  const TGCKpi({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = color ?? AppColors.primary;
    
    return TGC(
      variant: TGCVariant.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMuted : const Color(0xFF8A9891),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : const Color(0xFF10201A),
              letterSpacing: 0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : const Color(0xFF8A9891),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Gradient card for premium features
class TGCGradient extends StatelessWidget {
  final Widget child;
  final List<Color> gradient;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const TGCGradient({
    super.key,
    required this.child,
    this.gradient = const [AppColors.primary, Color(0xFF8B5CF6)],
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
