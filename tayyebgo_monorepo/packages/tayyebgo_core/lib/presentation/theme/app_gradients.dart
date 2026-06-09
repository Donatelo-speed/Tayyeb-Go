import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Premium gradient system — dark backgrounds with indigo accents.
abstract class AppGradients {
  // ── Primary Gradients ──
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primaryGradientHorizontal => const LinearGradient(
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get primaryGradientVertical => const LinearGradient(
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get primaryToDark => const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primaryToAccent => const LinearGradient(
        colors: [AppColors.primary, AppColors.accent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  // ── Surface (dark) ──
  static LinearGradient get warmGlow => const LinearGradient(
        colors: [AppColors.background, AppColors.surface],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get surfaceGradient => const LinearGradient(
        colors: [AppColors.surface, AppColors.surfaceAlt],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ── Sidebar ──
  static LinearGradient get sidebarGradient => const LinearGradient(
        colors: [AppColors.sidebarBg, Color(0xFF050508)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ── Overlays ──
  static LinearGradient get darkOverlay => LinearGradient(
        colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  // ── Shimmer (dark) ──
  static LinearGradient get shimmerGradient => LinearGradient(
        colors: [
          AppColors.surfaceAlt,
          AppColors.surface,
          AppColors.surfaceAlt,
        ],
        stops: const [0.0, 0.4, 1.0],
      );

  // ── Stat Gradients ──
  static LinearGradient get statBlue => const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statGreen => const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statOrange => const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statPurple => const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statCyan => const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ── Accents ──
  static LinearGradient get coolGradient => const LinearGradient(
        colors: [AppColors.cyan, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get warmGradient => const LinearGradient(
        colors: [AppColors.warning, Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
