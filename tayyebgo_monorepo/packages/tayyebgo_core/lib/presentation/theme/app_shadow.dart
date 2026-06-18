import 'package:flutter/material.dart';
import 'app_colors.dart';

/// TayyebGo shadow system.
///
/// Multi-layer elevation shadows with dark/light adaptive support.
/// All methods require [isDark] parameter for proper theme adaptation.
/// For context-aware access, use [ThemeColors] extensions from theme_provider.dart.
abstract class AppShadow {
  // ══════════════════════════════════════════════════════════════════════════
  // ELEVATION SHADOWS (5 tiers)
  // ══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> elevation0(bool isDark) => const [];

  static List<BoxShadow> elevation1(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x0F1D2736),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ];

  static List<BoxShadow> elevation2(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x141D2736),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x0A1D2736),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ];

  static List<BoxShadow> elevation3(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x1F1D2736),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ];

  static List<BoxShadow> elevation4(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 56,
            offset: Offset(0, 28),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x291D2736),
            blurRadius: 56,
            offset: Offset(0, 28),
          ),
        ];

  // ══════════════════════════════════════════════════════════════════════════
  // GLOW SHADOWS (colored, for interactive feedback)
  // ══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> glowPrimary(bool isDark) => [
        BoxShadow(
          color: (isDark ? AppColors.primary : LightAppColors.primary)
              .withValues(alpha: isDark ? 0.32 : 0.22),
          blurRadius: 26,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> glowSuccess(bool isDark) => [
        BoxShadow(
          color: (isDark ? AppColors.success : LightAppColors.success)
              .withValues(alpha: isDark ? 0.28 : 0.2),
          blurRadius: 24,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> glowError(bool isDark) => [
        BoxShadow(
          color: (isDark ? AppColors.error : LightAppColors.error)
              .withValues(alpha: isDark ? 0.28 : 0.2),
          blurRadius: 24,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> glowWarning(bool isDark) => [
        BoxShadow(
          color: (isDark ? AppColors.warning : LightAppColors.warning)
              .withValues(alpha: isDark ? 0.28 : 0.2),
          blurRadius: 24,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> glowInfo(bool isDark) => [
        BoxShadow(
          color: (isDark ? AppColors.info : LightAppColors.info)
              .withValues(alpha: isDark ? 0.28 : 0.2),
          blurRadius: 24,
          spreadRadius: -8,
        ),
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC ALIASES
  // ══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> cardSoft(bool isDark) => elevation1(isDark);
  static List<BoxShadow> cardMedium(bool isDark) => elevation2(isDark);
  static List<BoxShadow> cardStrong(bool isDark) => elevation3(isDark);
}
