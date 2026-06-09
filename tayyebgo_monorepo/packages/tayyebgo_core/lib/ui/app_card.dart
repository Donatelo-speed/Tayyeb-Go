import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';
import '../presentation/theme/app_shadow.dart';

/// TGC = TayyebGoCard — Unified card system
enum TGCVariant { surface, elevated, outlined, glass }

class TGC extends StatelessWidget {
  final Widget child;
  final TGCVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;

  const TGC({
    super.key,
    required this.child,
    this.variant = TGCVariant.surface,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.borderRadius,
  });

  // ── Named constructors ──
  const TGC.surface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
  })  : variant = TGCVariant.surface,
        color = null,
        gradient = null,
        borderRadius = null;

  const TGC.elevated({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
  })  : variant = TGCVariant.elevated,
        color = null,
        gradient = null,
        borderRadius = null;

  const TGC.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
  })  : variant = TGCVariant.outlined,
        color = null,
        gradient = null,
        borderRadius = null;

  const TGC.glass({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
  })  : variant = TGCVariant.glass,
        color = null,
        gradient = null,
        borderRadius = null;

  const TGC.gradient({
    super.key,
    required this.child,
    required this.gradient,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
  })  : variant = TGCVariant.elevated,
        color = null,
        borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? AppRadius.brCard;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          decoration: _decoration(isDark, br),
          child: ClipRRect(
            borderRadius: br,
            child: Material(
              color: Colors.transparent,
              child: onTap != null
                  ? InkWell(
                      onTap: onTap,
                      borderRadius: br,
                      child: Padding(
                        padding: padding ?? const EdgeInsets.all(16),
                        child: child,
                      ),
                    )
                  : Padding(
                      padding: padding ?? const EdgeInsets.all(16),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(bool isDark, BorderRadius br) {
    switch (variant) {
      case TGCVariant.surface:
        return BoxDecoration(
          color: color ?? (isDark ? AppColors.surface : AppColors.surface),
          borderRadius: br,
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.divider,
            width: 1,
          ),
        );

      case TGCVariant.elevated:
        return BoxDecoration(
          color: color ?? (isDark ? AppColors.surface : AppColors.surface),
          gradient: gradient,
          borderRadius: br,
          boxShadow: AppShadow.elevation2(isDark),
        );

      case TGCVariant.outlined:
        return BoxDecoration(
          color: color ?? Colors.transparent,
          borderRadius: br,
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.border,
            width: 1,
          ),
        );

      case TGCVariant.glass:
        return BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColors.glassSurface,
          borderRadius: br,
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        );
    }
  }
}

// ── KPI Card ──
class TGCKpi extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Gradient? gradient;
  final Color? iconColor;

  const TGCKpi({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.gradient,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TGC.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
                ),
              if (icon != null) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Backward compatibility alias
typedef AppCard = TGC;
