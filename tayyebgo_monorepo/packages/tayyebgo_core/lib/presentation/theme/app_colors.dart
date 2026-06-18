import 'package:flutter/material.dart';

/// TayyebGo brand color system.
///
/// The brand uses warm food-forward color, a fresh route accent, and quiet
/// operational neutrals so customer, driver, partner, and admin apps feel
/// related without becoming one orange screen.
abstract class AppColors {
  static const Color primary = Color(0xFFFF5A2C);
  static const Color primaryHover = Color(0xFFFF7A3D);
  static const Color primarySoft = Color(0x26FF5A2C);
  static const Color primaryAlt = Color(0xFFDB3E1D);
  static const Color primaryLight = Color(0x33FF5A2C);
  static const Color primaryDark = Color(0xFF9E2F18);

  static const Color accent = Color(0xFF35C88A);
  static const Color accentLight = Color(0x2635C88A);
  static const Color gradientStart = primary;
  static const Color gradientEnd = Color(0xFFFFB84D);
  static const Color route = Color(0xFF21B8A6);
  static const Color routeSoft = Color(0x2621B8A6);

  static const Color customerAccent = primary;
  static const Color driverAccent = Color(0xFF14B87A);
  static const Color partnerAccent = Color(0xFFF4A51C);
  static const Color adminAccent = Color(0xFF5263F3);

  static const Color info = Color(0xFF3E8CFF);
  static const Color premium = Color(0xFF8E5CF7);
  static const Color premiumSoft = Color(0x268E5CF7);
  static const Color purple = premium;
  static const Color cyan = Color(0xFF17B6D2);
  static const Color emerald = Color(0xFF15B87A);
  static const Color amber = Color(0xFFF4A51C);
  static const Color shadow = Color(0xFF050711);

  static const Color background = Color(0xFF090B10);
  static const Color surface = Color(0xFF121722);
  static const Color surfaceAlt = Color(0xFF1A2130);
  static const Color surfaceHover = Color(0xFF222B3B);
  static const Color surfaceElevated = Color(0xFF171D2A);
  static const Color surfaceSunken = Color(0xFF07090D);

  static const Color glassSurface = Color(0xB3121722);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassOverlay = Color(0x66000000);

  // ── Glassmorphism (dark/light variants for adaptive glass effects) ──
  static const Color darkGlass = Color(0xB3121722);
  static const Color darkGlassBorder = Color(0x1FFFFFFF);
  static const Color glowSecondary = Color(0x4021B8A6);
  static const Color glowAccent = Color(0x4035C88A);

  static const Color error = Color(0xFFFF4D5E);
  static const Color errorSoft = Color(0x26FF4D5E);
  static const Color success = Color(0xFF22C96D);
  static const Color successSoft = Color(0x2622C96D);
  static const Color warning = Color(0xFFFFC247);
  static const Color warningSoft = Color(0x26FFC247);
  static const Color infoSoft = Color(0x263E8CFF);

  static const Color glowPrimary = Color(0x40FF5A2C);
  static const Color glowSuccess = Color(0x3322C96D);
  static const Color glowError = Color(0x33FF4D5E);
  static const Color glowWarning = Color(0x33FFC247);

  static const Color textPrimary = Color(0xFFF7F9FC);
  static const Color textSecondary = Color(0xFFB8C0CC);
  static const Color textTertiary = Color(0xFF8792A3);
  static const Color textMuted = Color(0xFF6B7686);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color border = Color(0xFF273043);
  static const Color borderStrong = Color(0xFF3A465C);
  static const Color divider = Color(0xFF1E2635);

  static const Color ratingStar = Color(0xFFFFC247);
  static const Color scrim = Color(0x99000000);

  static const Color cardBackground = surface;
  static const Color overlay = scrim;

  static const Color sidebarBg = Color(0xFF080A0F);
  static const Color sidebarText = Color(0xFFE7EBF2);
  static const Color sidebarMuted = Color(0xFF8993A3);
  static const Color sidebarActive = primary;
  static const Color sidebarActiveBg = Color(0x1FFF5A2C);
  static const Color sidebarBorder = Color(0xFF1B2230);

  static const List<Color> revenueGradient = [primary, gradientEnd];
  static const List<Color> ordersGradient = [emerald, route];
  static const List<Color> driversGradient = [driverAccent, Color(0xFF45D4A3)];
  static const List<Color> storesGradient = [partnerAccent, Color(0xFFFFD36B)];

}

/// Light theme colors.
abstract class LightAppColors {
  static const Color primary = AppColors.primary;
  static const Color primaryHover = AppColors.primaryHover;
  static const Color primarySoft = Color(0xFFFFEFE8);
  static const Color primaryAlt = AppColors.primaryAlt;
  static const Color primaryLight = Color(0x29FF5A2C);
  static const Color primaryDark = AppColors.primaryDark;

  static const Color accent = AppColors.accent;
  static const Color accentLight = Color(0xFFE9FAF3);
  static const Color gradientStart = AppColors.gradientStart;
  static const Color gradientEnd = AppColors.gradientEnd;
  static const Color route = AppColors.route;
  static const Color routeSoft = Color(0xFFE7F8F5);

  static const Color customerAccent = AppColors.customerAccent;
  static const Color driverAccent = AppColors.driverAccent;
  static const Color partnerAccent = AppColors.partnerAccent;
  static const Color adminAccent = AppColors.adminAccent;

  static const Color info = AppColors.info;
  static const Color premium = AppColors.premium;
  static const Color premiumSoft = Color(0xFFF3EDFF);
  static const Color purple = AppColors.purple;
  static const Color cyan = AppColors.cyan;
  static const Color emerald = AppColors.emerald;
  static const Color amber = AppColors.amber;
  static const Color shadow = Color(0xFF1D2736);

  static const Color background = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF2F5F7);
  static const Color surfaceHover = Color(0xFFFFFAF6);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFEAEFF2);

  static const Color glassSurface = Color(0xD9FFFFFF);
  static const Color glassBorder = Color(0x80FFFFFF);
  static const Color glassOverlay = Color(0x33000000);

  // ── Glassmorphism (light variants for adaptive glass effects) ──
  static const Color lightGlass = Color(0xD9FFFFFF);
  static const Color lightGlassBorder = Color(0x80FFFFFF);
  static const Color glowSecondary = AppColors.glowSecondary;
  static const Color glowAccent = AppColors.glowAccent;

  static const Color error = AppColors.error;
  static const Color errorSoft = Color(0xFFFFEDF0);
  static const Color success = AppColors.success;
  static const Color successSoft = Color(0xFFEAFBF2);
  static const Color warning = Color(0xFFE69710);
  static const Color warningSoft = Color(0xFFFFF6DF);
  static const Color infoSoft = Color(0xFFECF4FF);

  static const Color glowPrimary = AppColors.glowPrimary;
  static const Color glowSuccess = AppColors.glowSuccess;
  static const Color glowError = AppColors.glowError;
  static const Color glowWarning = AppColors.glowWarning;

  static const Color textPrimary = Color(0xFF151922);
  static const Color textSecondary = Color(0xFF4B5564);
  static const Color textTertiary = Color(0xFF737F90);
  static const Color textMuted = Color(0xFF93A0AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFDCE3EA);
  static const Color borderStrong = Color(0xFFC6D0DA);
  static const Color divider = Color(0xFFE8EDF2);

  static const Color ratingStar = Color(0xFFE69710);
  static const Color scrim = Color(0x66000000);

  static const Color cardBackground = surface;
  static const Color overlay = scrim;

  static const Color sidebarBg = Color(0xFF0B1018);
  static const Color sidebarText = Color(0xFFE7EBF2);
  static const Color sidebarMuted = Color(0xFF909BAD);
  static const Color sidebarActive = AppColors.primary;
  static const Color sidebarActiveBg = Color(0x1FFF5A2C);
  static const Color sidebarBorder = Color(0xFF1C2636);

  static const List<Color> revenueGradient = AppColors.revenueGradient;
  static const List<Color> ordersGradient = AppColors.ordersGradient;
  static const List<Color> driversGradient = AppColors.driversGradient;
  static const List<Color> storesGradient = AppColors.storesGradient;
}
