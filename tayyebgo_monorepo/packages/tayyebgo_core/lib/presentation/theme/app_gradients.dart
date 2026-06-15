import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppGradients {
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

  static LinearGradient get freshRoute => const LinearGradient(
        colors: [AppColors.route, AppColors.driverAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get warmGlow => const LinearGradient(
        colors: [AppColors.background, Color(0xFF151820), AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get surfaceGradient => const LinearGradient(
        colors: [AppColors.surface, AppColors.surfaceAlt],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get lightAppBackground => const LinearGradient(
        colors: [Color(0xFFFFFAF6), LightAppColors.background, Color(0xFFEAF7F3)],
        stops: [0, 0.58, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get darkAppBackground => const LinearGradient(
        colors: [Color(0xFF0D1017), AppColors.background, Color(0xFF0A1114)],
        stops: [0, 0.62, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get sidebarGradient => const LinearGradient(
        colors: [AppColors.sidebarBg, Color(0xFF0F1622)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get darkOverlay => LinearGradient(
        colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  static LinearGradient get shimmerGradient => const LinearGradient(
        colors: [AppColors.surfaceAlt, AppColors.surfaceHover, AppColors.surfaceAlt],
        stops: [0.0, 0.45, 1.0],
      );

  static LinearGradient get statBlue => const LinearGradient(
        colors: [AppColors.adminAccent, Color(0xFF7A8CFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statGreen => const LinearGradient(
        colors: [AppColors.driverAccent, Color(0xFF45D4A3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statOrange => const LinearGradient(
        colors: [AppColors.partnerAccent, Color(0xFFFFD36B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statPurple => const LinearGradient(
        colors: [AppColors.premium, Color(0xFFB08CFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get statCyan => const LinearGradient(
        colors: [AppColors.cyan, AppColors.route],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

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
