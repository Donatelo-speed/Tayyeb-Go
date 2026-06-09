import 'package:flutter/material.dart';

/// Shared TayyebGo color system.
///
/// The brand palette uses charcoal surfaces, fresh green actions, and warm
/// food-service accents so the four apps feel related without becoming a
/// single-hue interface.
abstract class AppColors {
  // Brand
  static const Color primary = Color(0xFF00A676);
  static const Color primaryHover = Color(0xFF2DD4BF);
  static const Color primarySoft = Color(0xFF12362E);
  static const Color primaryAlt = Color(0xFF0E8F70);
  static const Color primaryLight = Color(0x1A00A676);
  static const Color primaryDark = Color(0xFF006B4F);
  static const Color accent = Color(0xFFFFB703);
  static const Color accentLight = Color(0x1AFFB703);

  // Gradients
  static const Color gradientStart = Color(0xFF00A676);
  static const Color gradientEnd = Color(0xFFFFB703);

  // Semantic
  static const Color info = Color(0xFF06B6D4);
  static const Color premium = Color(0xFF7C3AED);
  static const Color premiumSoft = Color(0x1A7C3AED);
  static const Color purple = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color shadow = Color(0xFF050706);

  // Surfaces
  static const Color background = Color(0xFF0B0F0E);
  static const Color surface = Color(0xFF121816);
  static const Color surfaceAlt = Color(0xFF1A2420);
  static const Color surfaceHover = Color(0xFF21302A);
  static const Color surfaceElevated = Color(0xFF17201D);
  static const Color surfaceSunken = Color(0xFF080B0A);

  // Glass
  static const Color glassSurface = Color(0x26121816);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassOverlay = Color(0x66000000);

  // Status
  static const Color error = Color(0xFFF87171);
  static const Color errorSoft = Color(0x1AF87171);
  static const Color success = Color(0xFF34D399);
  static const Color successSoft = Color(0x1A34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningSoft = Color(0x1AFBBF24);
  static const Color infoSoft = Color(0x1A06B6D4);

  // Glow
  static const Color glowPrimary = Color(0x3300A676);
  static const Color glowSuccess = Color(0x3334D399);
  static const Color glowError = Color(0x33F87171);
  static const Color glowWarning = Color(0x33FBBF24);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAF8);
  static const Color textSecondary = Color(0xFFC8D6CF);
  static const Color textTertiary = Color(0xFF9AA9A1);
  static const Color textMuted = Color(0xFF7A8780);
  static const Color textInverse = Color(0xFF07100C);

  // Borders
  static const Color border = Color(0xFF26352F);
  static const Color borderStrong = Color(0xFF365047);
  static const Color divider = Color(0xFF1D2924);

  // Rating
  static const Color ratingStar = Color(0xFFFFB703);

  // Scrim
  static const Color scrim = Color(0x99000000);

  // Legacy aliases
  static const Color cardBackground = surface;
  static const Color overlay = scrim;

  // Sidebar
  static const Color sidebarBg = Color(0xFF090D0B);
  static const Color sidebarText = Color(0xFFC8D6CF);
  static const Color sidebarMuted = Color(0xFF7A8780);
  static const Color sidebarActive = primary;
  static const Color sidebarActiveBg = primaryLight;
  static const Color sidebarBorder = Color(0xFF16211D);

  // Chart and stat gradients
  static const List<Color> revenueGradient = [primary, cyan];
  static const List<Color> ordersGradient = [emerald, primaryHover];
  static const List<Color> driversGradient = [amber, warning];
  static const List<Color> storesGradient = [Color(0xFFFF6B35), accent];

  // Dark aliases
  static const Color surfaceDark = background;
  static const Color darkBg = background;

  // Per-app accents
  static const Color customerAccent = Color(0xFFFF6B35);
  static const Color driverAccent = Color(0xFF10B981);
  static const Color partnerAccent = Color(0xFFF59E0B);
  static const Color adminAccent = Color(0xFF06B6D4);
}

typedef DarkAppColors = AppColors;

/// Light theme colors.
abstract class LightAppColors {
  // Brand
  static const Color primary = Color(0xFF008B6A);
  static const Color primaryHover = Color(0xFF047857);
  static const Color primarySoft = Color(0xFFE3F7EF);
  static const Color primaryAlt = Color(0xFF00765A);
  static const Color primaryLight = Color(0x1A008B6A);
  static const Color primaryDark = Color(0xFF005940);
  static const Color accent = Color(0xFFFFB703);
  static const Color accentLight = Color(0x1AFFB703);

  // Gradients
  static const Color gradientStart = Color(0xFF008B6A);
  static const Color gradientEnd = Color(0xFFFFB703);

  // Semantic
  static const Color info = Color(0xFF0891B2);
  static const Color premium = Color(0xFF7C3AED);
  static const Color premiumSoft = Color(0xFFEDE9FE);
  static const Color purple = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF0891B2);
  static const Color emerald = Color(0xFF059669);
  static const Color amber = Color(0xFFD97706);
  static const Color shadow = Color(0xFF0F172A);

  // Surfaces
  static const Color background = Color(0xFFF6F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF3F0);
  static const Color surfaceHover = Color(0xFFF9FBFA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFE8EFEC);

  // Glass
  static const Color glassSurface = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassOverlay = Color(0x4D000000);

  // Status
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // Glow
  static const Color glowPrimary = Color(0x33008B6A);
  static const Color glowSuccess = Color(0x33059669);
  static const Color glowError = Color(0x33DC2626);
  static const Color glowWarning = Color(0x33D97706);

  // Typography
  static const Color textPrimary = Color(0xFF10201A);
  static const Color textSecondary = Color(0xFF40534B);
  static const Color textTertiary = Color(0xFF62756C);
  static const Color textMuted = Color(0xFF8A9891);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFDDE7E2);
  static const Color borderStrong = Color(0xFFBCCDC5);
  static const Color divider = Color(0xFFEAF0ED);

  // Rating
  static const Color ratingStar = Color(0xFFFFB703);

  // Scrim
  static const Color scrim = Color(0x66000000);

  // Legacy aliases
  static const Color cardBackground = surface;
  static const Color overlay = scrim;

  // Sidebar
  static const Color sidebarBg = Color(0xFF10201A);
  static const Color sidebarText = Color(0xFFEAF0ED);
  static const Color sidebarMuted = Color(0xFF9AA9A1);
  static const Color sidebarActive = primary;
  static const Color sidebarActiveBg = primaryLight;
  static const Color sidebarBorder = Color(0xFF1F332B);

  // Chart and stat gradients
  static const List<Color> revenueGradient = [primary, cyan];
  static const List<Color> ordersGradient = [emerald, Color(0xFF10B981)];
  static const List<Color> driversGradient = [amber, accent];
  static const List<Color> storesGradient = [Color(0xFFFF6B35), accent];

  // Dark aliases
  static const Color surfaceDark = surface;
  static const Color darkBg = background;
}
