import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppGradients {
  static const _primary = AppColors.primary;
  static const _primaryDark = AppColors.primaryDark;
  static const _accent = AppColors.accent;

  static LinearGradient get primaryToDark => LinearGradient(
        colors: [_primary, _primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primaryToAccent => LinearGradient(
        colors: [_primary, _accent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get warmGlow => LinearGradient(
        colors: [
          AppColors.background,
          AppColors.surfaceAlt,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get sidebarGradient => LinearGradient(
        colors: [
          AppColors.sidebarBg,
          const Color(0xFF020617),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get darkOverlay => LinearGradient(
        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  static LinearGradient get shimmerGradient => LinearGradient(
        colors: [
          Colors.grey.shade200,
          Colors.grey.shade100,
          Colors.grey.shade200,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  static LinearGradient get statBlue => LinearGradient(
        colors: [AppColors.info, const Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statGreen => LinearGradient(
        colors: [AppColors.success, const Color(0xFF16A34A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statOrange => LinearGradient(
        colors: [AppColors.warning, const Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statPurple => LinearGradient(
        colors: [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statCyan => LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
