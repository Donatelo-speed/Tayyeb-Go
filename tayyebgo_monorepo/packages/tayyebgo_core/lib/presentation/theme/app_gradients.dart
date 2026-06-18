import 'package:flutter/material.dart';
import 'app_colors.dart';

/// TayyebGo gradient system.
///
/// Pre-built gradients using design token colors. No inline hex values.
abstract class AppGradients {
  // ══════════════════════════════════════════════════════════════════════════
  // PRIMARY GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // BRAND GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  static LinearGradient get freshRoute => const LinearGradient(
        colors: [AppColors.route, AppColors.driverAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get warmGlow => LinearGradient(
        colors: [AppColors.background, AppColors.surfaceAlt, AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get surfaceGradient => const LinearGradient(
        colors: [AppColors.surface, AppColors.surfaceAlt],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // APP BACKGROUND GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  static LinearGradient get lightAppBackground => LinearGradient(
        colors: [LightAppColors.surface, LightAppColors.background, LightAppColors.surfaceAlt],
        stops: const [0, 0.58, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get darkAppBackground => LinearGradient(
        colors: [AppColors.surfaceAlt, AppColors.background, AppColors.surfaceSunken],
        stops: const [0, 0.62, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get sidebarGradient => LinearGradient(
        colors: [AppColors.sidebarBg, AppColors.surfaceAlt],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get darkOverlay => LinearGradient(
        colors: [AppColors.scrim, Colors.transparent],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // LOADING / UTILITY GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  static LinearGradient get shimmerGradient => const LinearGradient(
        colors: [AppColors.surfaceAlt, AppColors.surfaceHover, AppColors.surfaceAlt],
        stops: [0.0, 0.45, 1.0],
      );

  // ══════════════════════════════════════════════════════════════════════════
  // STAT / DASHBOARD GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  static LinearGradient get statBlue => LinearGradient(
        colors: [AppColors.adminAccent, AppColors.adminAccent.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statGreen => LinearGradient(
        colors: [AppColors.driverAccent, AppColors.driverAccent.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statOrange => LinearGradient(
        colors: [AppColors.partnerAccent, AppColors.partnerAccent.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statPurple => LinearGradient(
        colors: [AppColors.premium, AppColors.premium.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statCyan => LinearGradient(
        colors: [AppColors.cyan, AppColors.route],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITY GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  static LinearGradient get coolGradient => const LinearGradient(
        colors: [AppColors.route, AppColors.cyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get warmGradient => const LinearGradient(
        colors: [AppColors.primary, AppColors.partnerAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
