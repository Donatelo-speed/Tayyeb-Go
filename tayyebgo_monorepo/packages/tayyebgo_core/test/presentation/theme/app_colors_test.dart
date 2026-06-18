import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tayyebgo_core/presentation/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary brand color is correct hex', () {
      expect(AppColors.primary, const Color(0xFFFF5A2C));
    });

    test('primaryHover is lighter than primary', () {
      expect(AppColors.primaryHover, const Color(0xFFFF7A3D));
    });

    test('primarySoft has low alpha', () {
      expect(AppColors.primarySoft.alpha, lessThan(50));
    });

    test('surface colors are dark (dark theme)', () {
      expect(AppColors.background.value, 0xFF090B10);
      expect(AppColors.surface.value, 0xFF121722);
    });

    test('glassmorphism tokens exist', () {
      expect(AppColors.glassSurface, isNotNull);
      expect(AppColors.glassBorder, isNotNull);
      expect(AppColors.glassOverlay, isNotNull);
      expect(AppColors.darkGlass, isNotNull);
      expect(AppColors.darkGlassBorder, isNotNull);
    });

    test('semantic colors defined', () {
      expect(AppColors.error, const Color(0xFFFF4D5E));
      expect(AppColors.success, const Color(0xFF22C96D));
      expect(AppColors.warning, const Color(0xFFFFC247));
      expect(AppColors.info, const Color(0xFF3E8CFF));
    });

    test('text colors hierarchy', () {
      expect(AppColors.textPrimary, const Color(0xFFF7F9FC));
      expect(AppColors.textSecondary, const Color(0xFFB8C0CC));
      expect(AppColors.textTertiary, const Color(0xFF8792A3));
      expect(AppColors.textMuted, const Color(0xFF6B7686));
    });

    test('glow colors for hover/focus effects', () {
      expect(AppColors.glowPrimary, isNotNull);
      expect(AppColors.glowSuccess, isNotNull);
      expect(AppColors.glowError, isNotNull);
      expect(AppColors.glowWarning, isNotNull);
    });

    test('platform accent colors', () {
      expect(AppColors.customerAccent, AppColors.primary);
      expect(AppColors.driverAccent, const Color(0xFF14B87A));
      expect(AppColors.partnerAccent, const Color(0xFFF4A51C));
      expect(AppColors.adminAccent, const Color(0xFF5263F3));
    });

    test('gradient colors', () {
      expect(AppColors.gradientStart, AppColors.primary);
      expect(AppColors.gradientEnd, const Color(0xFFFFB84D));
    });

    test('sidebar colors', () {
      expect(AppColors.sidebarBg, const Color(0xFF080A0F));
      expect(AppColors.sidebarActive, AppColors.primary);
    });
  });

  group('LightAppColors', () {
    test('primary matches AppColors primary', () {
      expect(LightAppColors.primary, AppColors.primary);
    });

    test('surface is white', () {
      expect(LightAppColors.surface, const Color(0xFFFFFFFF));
    });

    test('background is warm light', () {
      expect(LightAppColors.background, const Color(0xFFF7F4EF));
    });

    test('textPrimary is dark', () {
      expect(LightAppColors.textPrimary, const Color(0xFF151922));
    });

    test('glassSurface is white-based', () {
      expect(LightAppColors.glassSurface.alpha, greaterThan(200));
    });

    test('soft colors have high alpha (light theme)', () {
      expect(LightAppColors.errorSoft.alpha, 0xFF);
      expect(LightAppColors.successSoft.alpha, 0xFF);
    });
  });
}
