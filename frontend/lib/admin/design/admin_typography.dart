import 'package:flutter/material.dart';
import 'admin_colors.dart';
import 'admin_spacing.dart';

class AdminTypography {
  AdminTypography._();
  static const _font = 'Inter';

  static TextStyle display(bool isDark) => TextStyle(
    fontSize: 36, fontWeight: FontWeight.w800, fontFamily: _font,
    color: AdminColors.textPrimary(isDark), letterSpacing: -1, height: 1.1,
  );
  static TextStyle h1(bool isDark) => TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, fontFamily: _font,
    color: AdminColors.textPrimary(isDark), letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle h2(bool isDark) => TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, fontFamily: _font,
    color: AdminColors.textPrimary(isDark), letterSpacing: -0.3, height: 1.3,
  );
  static TextStyle h3(bool isDark) => TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, fontFamily: _font,
    color: AdminColors.textPrimary(isDark), height: 1.4,
  );
  static TextStyle h4(bool isDark) => TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _font,
    color: AdminColors.textPrimary(isDark), height: 1.4,
  );
  static TextStyle body(bool isDark) => TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, fontFamily: _font,
    color: AdminColors.textPrimary(isDark), height: 1.5,
  );
  static TextStyle bodySmall(bool isDark) => TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, fontFamily: _font,
    color: AdminColors.textSecondary(isDark), height: 1.4,
  );
  static TextStyle caption(bool isDark) => TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _font,
    color: AdminColors.textMuted(isDark), height: 1.3,
  );
  static TextStyle label(bool isDark) => TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, fontFamily: _font,
    color: AdminColors.textSecondary(isDark), letterSpacing: 0.5, height: 1.3,
  );
  static TextStyle overline(bool isDark) => TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, fontFamily: _font,
    color: AdminColors.textMuted(isDark), letterSpacing: 1.5, height: 1.3,
  );
  static TextStyle mono(bool isDark) => TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'JetBrains Mono',
    color: AdminColors.textSecondary(isDark), height: 1.5,
  );
  static TextStyle button = const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, fontFamily: _font, letterSpacing: 0.2,
  );
  static TextStyle kpiValue(bool isDark) => TextStyle(
    fontSize: 32, fontWeight: FontWeight.w800, fontFamily: _font,
    color: AdminColors.textPrimary(isDark), letterSpacing: -0.5, height: 1,
  );
  static TextStyle kpiLabel(bool isDark) => TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, fontFamily: _font,
    color: AdminColors.textSecondary(isDark), height: 1.3,
  );
  static TextStyle breadcrumb(bool isDark) => TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, fontFamily: _font,
    color: AdminColors.textMuted(isDark),
  );
  static TextStyle breadcrumbActive(bool isDark) => TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, fontFamily: _font,
    color: AdminColors.textPrimary(isDark),
  );
}

class AdminShadows {
  AdminShadows._();

  static List<BoxShadow> sm(bool isDark) => [
    BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x08000000), blurRadius: 2, offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> md(bool isDark) => [
    BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0x0A000000), blurRadius: 4, offset: const Offset(0, 2)),
    BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x05000000), blurRadius: 8, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> lg(bool isDark) => [
    BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0x0F000000), blurRadius: 8, offset: const Offset(0, 4)),
    BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x08000000), blurRadius: 16, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> top = [
    const BoxShadow(color: Color(0x06000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

BoxDecoration cardDecoration(bool isDark) => BoxDecoration(
  color: AdminColors.card(isDark),
  borderRadius: BorderRadius.circular(AdminRadius.xl),
  border: Border.all(color: AdminColors.border(isDark), width: 0.5),
  boxShadow: AdminShadows.sm(isDark),
);