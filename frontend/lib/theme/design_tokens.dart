import 'package:flutter/material.dart';

class TayyebGoColors {
  TayyebGoColors._();

  static const primary = Color(0xFF00C853);
  static const primaryDark = Color(0xFF009624);
  static const primaryLight = Color(0xFF5CF08E);
  static const primarySurface = Color(0xFFE8F5E9);

  static const secondary = Color(0xFFFF6B35);
  static const secondaryLight = Color(0xFFFF8F5C);

  static const accent = Color(0xFF00BCD4);

  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F2F5);

  static const darkBg = Color(0xFF0A0D14);
  static const darkSurface = Color(0xFF141822);
  static const darkSurfaceAlt = Color(0xFF1C2130);
  static const darkCard = Color(0xFF1E2333);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const textInverse = Color(0xFFF9FAFB);

  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static const divider = Color(0xFFE5E7EB);
  static const darkDivider = Color(0xFF2C3248);

  static const shimmerBase = Color(0xFFE8EAEE);
  static const shimmerHighlight = Color(0xFFF8F9FC);
  static const shimmerDarkBase = Color(0xFF1E2433);
  static const shimmerDarkHighlight = Color(0xFF2A3144);

  static const glassLight = Color(0x0DFFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);
}

class TayyebGoGradients {
  TayyebGoGradients._();

  static const hero = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroWarm = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const vibrant = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00BCD4), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accent = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkBg = LinearGradient(
    colors: [Color(0xFF0A0D14), Color(0xFF141822), Color(0xFF0F1629)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkOverlay = LinearGradient(
    colors: [Color(0xCC0A0D14), Color(0x990A0D14)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const sunset = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFFFF6B35), Color(0xFFFF8F5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class TayyebGoTokens {
  TayyebGoTokens._();

  static const radiusXs = 6.0;
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;
  static const radiusXl = 24.0;
  static const radius2xl = 32.0;
  static const radiusFull = 999.0;

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 24.0;
  static const space2xl = 32.0;
  static const space3xl = 48.0;

  static const durationFast = Duration(milliseconds: 200);
  static const durationNormal = Duration(milliseconds: 350);
  static const durationSlow = Duration(milliseconds: 600);
  static const durationPage = Duration(milliseconds: 450);

  static const curveStandard = Curves.easeOutCubic;
  static const curveBouncy = Curves.elasticOut;
  static const curveSmooth = Curves.easeInOut;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Color(0xFF00C853).withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 60,
          offset: const Offset(0, 24),
        ),
      ];

  static List<BoxShadow> get glowPrimary => [
        BoxShadow(
          color: const Color(0xFF00C853).withValues(alpha: 0.3),
          blurRadius: 20,
          offset: Offset.zero,
        ),
      ];

  static TextTheme textTheme(String fontFamily) => TextTheme(
        displayLarge: TextStyle(
            fontSize: 36, fontWeight: FontWeight.bold, color: TayyebGoColors.textPrimary, letterSpacing: -0.5, height: 1.2),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: TayyebGoColors.textPrimary, letterSpacing: -0.3, height: 1.3),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: TayyebGoColors.textPrimary, height: 1.3),
        headlineLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: TayyebGoColors.textPrimary, height: 1.3),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: TayyebGoColors.textPrimary, height: 1.3),
        headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: TayyebGoColors.textPrimary, height: 1.3),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w500, color: TayyebGoColors.textPrimary, height: 1.4),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: TayyebGoColors.textPrimary, height: 1.4),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: TayyebGoColors.textPrimary, height: 1.4),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.normal, color: TayyebGoColors.textPrimary, height: 1.6),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.normal, color: TayyebGoColors.textSecondary, height: 1.6),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.normal, color: TayyebGoColors.textMuted, height: 1.5),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: TayyebGoColors.textPrimary, height: 1.4, letterSpacing: 0.3),
        labelSmall: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: TayyebGoColors.textMuted, letterSpacing: 0.5, height: 1.4),
      );
}