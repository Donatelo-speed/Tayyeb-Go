import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/shared_widgets/animated_widgets.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? accentColor;

  const EmptyState({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.primary;
    
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
                    colors: [
                      accent.withValues(alpha: 0.15),
                      accent.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: accent.withValues(alpha: 0.7),
                ),
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
                  color: isDark ? AppColors.textPrimary : const Color(0xFF10201A),
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
                    color: isDark ? AppColors.textSecondary : const Color(0xFF40534B),
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
                child: AnimatedPressScale(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      actionText!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Modern skeleton loading with shimmer effect
class ModernSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;

  const ModernSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ShimmerWidget(
      child: Container(
        width: isCircle ? height : width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAlt : const Color(0xFFEEF3F0),
          borderRadius: BorderRadius.circular(isCircle ? (height ?? 48) / 2 : borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for restaurant cards
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModernSkeleton(
            width: double.infinity,
            height: 160,
            borderRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernSkeleton(width: 150, height: 18),
                const SizedBox(height: 8),
                const ModernSkeleton(width: 100, height: 14),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const ModernSkeleton(width: 60, height: 24, borderRadius: 12),
                    const SizedBox(width: 12),
                    const ModernSkeleton(width: 80, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for list items
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const ModernSkeleton(width: 48, height: 48, borderRadius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernSkeleton(width: 120, height: 16),
                const SizedBox(height: 8),
                const ModernSkeleton(width: 80, height: 12),
              ],
            ),
          ),
          const ModernSkeleton(width: 60, height: 16),
        ],
      ),
    );
  }
}

/// Skeleton for horizontal scroll items
class HorizontalSkeleton extends StatelessWidget {
  final double itemWidth;
  final int itemCount;

  const HorizontalSkeleton({
    super.key,
    this.itemWidth = 160,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          return SizedBox(
            width: itemWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernSkeleton(
                  width: itemWidth,
                  height: 100,
                  borderRadius: 14,
                ),
                const SizedBox(height: 8),
                ModernSkeleton(width: itemWidth * 0.7, height: 14),
                const SizedBox(height: 6),
                ModernSkeleton(width: itemWidth * 0.5, height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
