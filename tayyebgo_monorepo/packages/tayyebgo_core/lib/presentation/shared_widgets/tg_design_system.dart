import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadow.dart';
import '../theme/theme_provider.dart';
import 'animated_widgets.dart';
import 'brand_logo.dart';

/// TayyebGo Unified Design System
/// All apps use these components for consistency

// ═══════════════════════════════════════════
// HAPTIC FEEDBACK
// ═══════════════════════════════════════════

class TGHaptics {
  static void tap() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.lightImpact());
  }
  static void error() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.heavyImpact());
  }
}

// ═══════════════════════════════════════════
// LOADING STATES
// ═══════════════════════════════════════════

/// Consistent loading indicator for all apps
class TGLoader extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const TGLoader({super.key, this.message, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: color ?? context.primaryColor,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.inter(
                color: context.textMutedColor,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading with branded background
class TGFullScreenLoader extends StatelessWidget {
  final String? message;

  const TGFullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TayyebGoAnimatedLogo(size: 64),
          const SizedBox(height: 24),
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: context.primaryColor,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.inter(
                color: context.textMutedColor,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// EMPTY STATES
// ═══════════════════════════════════════════

/// Unified empty state for all apps
class TGEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? accentColor;

  const TGEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScaleIn(
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(icon, size: 44, color: color.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedFadeSlide(
              delay: 100,
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : LightAppColors.textPrimary,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              AnimatedFadeSlide(
                delay: 200,
                child: Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textMutedColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 28),
              AnimatedFadeSlide(
                delay: 300,
                child: TGButton(
                  label: actionText!,
                  onTap: onAction,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// ERROR STATES
// ═══════════════════════════════════════════

/// Unified error state for all apps
class TGError extends StatelessWidget {
  final String? title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;

  const TGError({
    super.key,
    this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? 'Something went wrong',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimary
                    : LightAppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                color: context.textMutedColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              TGButton(
                label: actionText!,
                onTap: onAction,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// BUTTONS
// ═══════════════════════════════════════════

/// Primary gradient button
class TGButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final double height;

  const TGButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.icon,
    this.isLoading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    return AnimatedPressScale(
      onTap: isLoading ? null : () {
        TGHaptics.tap();
        onTap?.call();
      },
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
          ),
          borderRadius: AppRadius.brButton,
          boxShadow: AppShadow.glowPrimary(context.isDark),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary/outlined button
class TGButtonSecondary extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const TGButtonSecondary({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressScale(
      onTap: () {
        TGHaptics.tap();
        onTap?.call();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brButton,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: context.textPrimaryColor, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CARDS
// ═══════════════════════════════════════════

/// Standard card for all apps
class TGCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const TGCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressScale(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? context.surfaceColor,
          borderRadius: AppRadius.brCard,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: AppShadow.elevation1(context.isDark),
        ),
        child: child,
      ),
    );
  }
}

/// Gradient card for premium/featured content
class TGGradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradient;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const TGGradientCard({
    super.key,
    required this.child,
    this.gradient = const [AppColors.primary, AppColors.primaryHover],
    this.padding,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadow.elevation2(context.isDark),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════
// SECTION HEADERS
// ═══════════════════════════════════════════

/// Consistent section header with colored marker
class TGSection extends StatelessWidget {
  final String title;
  final Color? color;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const TGSection({
    super.key,
    required this.title,
    this.color,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? AppColors.primary;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accentColor, accentColor.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimary
                : LightAppColors.textPrimary,
            letterSpacing: 0,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          AnimatedPressScale(
            onTap: () {
              TGHaptics.light();
              onTrailingTap?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trailing!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════
// STAT CARDS
// ═══════════════════════════════════════════

/// Consistent stat card for dashboards
class TGStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const TGStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return TGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimary
                  : LightAppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// LIST ITEMS
// ═══════════════════════════════════════════

/// Consistent list item for settings, menus, etc.
class TGListItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const TGListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressScale(
      onTap: onTap != null ? () {
        TGHaptics.light();
        onTap!();
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brCard,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textPrimary
                          : LightAppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        color: context.textMutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// PULL TO REFRESH WRAPPER
// ═══════════════════════════════════════════

/// Wrapper that adds pull-to-refresh to any scrollable
class TGRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const TGRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: context.surfaceColor,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════
// SKELETON LOADERS
// ═══════════════════════════════════════════

/// Skeleton loader for stat cards
class TGStatSkeleton extends StatelessWidget {
  const TGStatSkeleton();

  @override
  Widget build(BuildContext context) {
    return TGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: AppRadius.brMd,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80, height: 24,
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60, height: 14,
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for list items
class TGListItemSkeleton extends StatelessWidget {
  const TGListItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return TGCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: AppRadius.brMd,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120, height: 16,
                  decoration: BoxDecoration(
                    color: context.surfaceAltColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80, height: 12,
                  decoration: BoxDecoration(
                    color: context.surfaceAltColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for horizontal scroll items
class TGHorizontalSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemWidth;

  const TGHorizontalSkeleton({this.itemCount = 4, this.itemWidth = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: itemWidth,
          child: TGCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity, height: 100,
                  decoration: BoxDecoration(
                    color: context.surfaceAltColor,
                    borderRadius: AppRadius.brMd,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 100, height: 14,
                  decoration: BoxDecoration(
                    color: context.surfaceAltColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60, height: 12,
                  decoration: BoxDecoration(
                    color: context.surfaceAltColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
