import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/theme_provider.dart';
import 'brand_logo.dart';
import 'animated_widgets.dart';
import '../../ui/app_button.dart';
import '../../ui/app_card.dart';

/// TayyebGo Unified Design System (Legacy)
/// All apps use these components for consistency.
///
/// IMPORTANT: New code should import from tayyebgo_ui.dart instead.
/// This file is kept for backward compatibility only.

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
                child: TGB(
                  label: actionText!,
                  onPressed: onAction,
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
              TGB(
                label: actionText!,
                onPressed: onAction,
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
          GestureDetector(
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
    return TGC(
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
    return GestureDetector(
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
    return TGC(
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
    return TGC(
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
          child: TGC(
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

// ═══════════════════════════════════════════
// ORDER TIMELINE
// ═══════════════════════════════════════════

/// Uber-style order timeline for live tracking
class TGOrderTimeline extends StatelessWidget {
  final List<TGTimelineStep> steps;
  final int currentStep;

  const TGOrderTimeline({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : context.surfaceAltColor,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : isCurrent
                          ? Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? AppColors.primary
                        : context.surfaceAltColor,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: GoogleFonts.inter(
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                        color: isCompleted || isCurrent
                            ? AppColors.textPrimary
                            : context.textMutedColor,
                      ),
                    ),
                    if (step.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textMutedColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (step.time != null)
              Text(
                step.time!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMutedColor,
                ),
              ),
          ],
        );
      }),
    );
  }
}

class TGTimelineStep {
  final String title;
  final String? subtitle;
  final String? time;

  const TGTimelineStep({
    required this.title,
    this.subtitle,
    this.time,
  });
}

// ═══════════════════════════════════════════
// PRICE DISPLAY
// ═══════════════════════════════════════════

/// Consistent price display across all apps
class TGPrice extends StatelessWidget {
  final double amount;
  final String currency;
  final TextStyle? style;
  final bool showCurrency;

  const TGPrice({
    super.key,
    required this.amount,
    this.currency = '\$',
    this.style,
    this.showCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: isDark ? AppColors.textPrimary : LightAppColors.textPrimary,
    );

    return Text(
      '${showCurrency ? currency : ''}${amount.toStringAsFixed(2)}',
      style: style ?? defaultStyle,
    );
  }
}

// ═══════════════════════════════════════════
// DELIVERY TIME BADGE
// ═══════════════════════════════════════════

/// Delivery time estimate badge
class TGDeliveryBadge extends StatelessWidget {
  final int minutes;
  final bool isSmall;

  const TGDeliveryBadge({
    super.key,
    required this.minutes,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: isSmall ? 12 : 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes}min',
            style: GoogleFonts.inter(
              fontSize: isSmall ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// AVATAR WITH FALLBACK
// ═══════════════════════════════════════════

/// User avatar with network image and initials fallback
class TGUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;

  const TGUserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(bgColor),
        ),
      );
    }

    return _buildInitials(bgColor);
  }

  Widget _buildInitials(Color bgColor) {
    final initials = (name ?? '?')
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

