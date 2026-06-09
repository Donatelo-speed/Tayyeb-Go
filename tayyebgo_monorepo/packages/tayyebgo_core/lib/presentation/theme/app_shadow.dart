import 'package:flutter/material.dart';

abstract class AppShadow {
  // ── Elevation Levels ──
  static List<BoxShadow> elevation0(bool isDark) => [];

  static List<BoxShadow> elevation1(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 1)),
        ]
      : const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0D0F172A), blurRadius: 3, offset: Offset(0, 1)),
        ];

  static List<BoxShadow> elevation2(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
        ]
      : const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
        ];

  static List<BoxShadow> elevation3(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 8)),
        ]
      : const [
          BoxShadow(color: Color(0x1F0F172A), blurRadius: 24, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, 4)),
        ];

  static List<BoxShadow> elevation4(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0xB3000000), blurRadius: 48, offset: Offset(0, 16)),
        ]
      : const [
          BoxShadow(color: Color(0x290F172A), blurRadius: 48, offset: Offset(0, 16)),
          BoxShadow(color: Color(0x1A0F172A), blurRadius: 12, offset: Offset(0, 8)),
        ];

  // ── Glow Effects ──
  static List<BoxShadow> glowPrimary(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x3300A676) : const Color(0x33008B6A),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> glowSuccess(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x3334D399) : const Color(0x33059669),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> glowError(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x33F87171) : const Color(0x33EF4444),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  // ── Legacy aliases ──
  static List<BoxShadow> cardSoft(bool isDark) => elevation1(isDark);
  static List<BoxShadow> cardMedium(bool isDark) => elevation2(isDark);
  static List<BoxShadow> cardStrong(bool isDark) => elevation3(isDark);

  // ── Convenience getters (no isDark param, defaults to light) ──
  static List<BoxShadow> get card => elevation1(false);
  static List<BoxShadow> get elevated => elevation2(false);
  static List<BoxShadow> get level3 => elevation3(false);
}
