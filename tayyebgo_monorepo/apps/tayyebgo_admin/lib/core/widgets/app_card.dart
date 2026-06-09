import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final VoidCallback? onTap;
  final BoxBorder? border;

  const AdminCard({
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
    return TGC(
      variant: elevated ? TGCVariant.elevated : TGCVariant.outlined,
      padding: padding,
      margin: margin,
      onTap: onTap,
      color: backgroundColor,
      child: child,
    );
  }
}

BoxDecoration appCardDecoration(BuildContext context, {Color? borderColor, double radius = AppRadius.md, bool elevated = false}) {
  return BoxDecoration(
    color: context.cardBackgroundColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor ?? context.borderColor,
      width: 1,
    ),
    boxShadow: elevated ? AppShadow.cardSoft(context.isDark) : null,
  );
}

BoxDecoration appCardBorderedDecoration(BuildContext context, {Color? borderColor}) {
  return BoxDecoration(
    color: context.cardBackgroundColor,
    borderRadius: AppRadius.brCard,
    border: Border.all(color: borderColor ?? context.borderColor),
  );
}

Container pageContainer(BuildContext context, {required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: context.isDark
            ? [context.backgroundColor, const Color(0xFF050810)]
            : [context.backgroundColor, context.surfaceAltColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: child,
  );
}
