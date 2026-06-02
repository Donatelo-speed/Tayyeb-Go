import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_shadow.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final VoidCallback? onTap;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.radius = AppRadius.md,
    this.elevated = false,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decoration = BoxDecoration(
      color: backgroundColor ?? context.cardBackgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(
        color: borderColor ?? (isDark ? DarkAppColors.border : AppColors.border),
        width: 1,
      ),
      boxShadow: elevated ? AppShadow.cardSoft(isDark) : null,
    );
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: decoration,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

BoxDecoration appCardDecoration(BuildContext context, {Color? borderColor, double radius = AppRadius.md, bool elevated = false}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: context.cardBackgroundColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor ?? (isDark ? DarkAppColors.border : AppColors.border),
      width: 1,
    ),
    boxShadow: elevated ? AppShadow.cardSoft(isDark) : null,
  );
}

BoxDecoration appCardBorderedDecoration(BuildContext context, {Color? borderColor}) {
  return BoxDecoration(
    color: context.cardBackgroundColor,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: borderColor ?? context.borderColor),
  );
}

Container pageContainer(BuildContext context, {required Widget child}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [DarkAppColors.background, Color(0xFF050810)]
            : [AppColors.background, AppColors.surfaceAlt],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: child,
  );
}
