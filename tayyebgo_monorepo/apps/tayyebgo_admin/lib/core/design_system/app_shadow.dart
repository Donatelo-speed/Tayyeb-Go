import 'package:flutter/material.dart';

abstract class AppShadow {
  static List<BoxShadow> cardSoft(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2)),
        ]
      : const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0F0F172A), blurRadius: 3, offset: Offset(0, 1)),
        ];

  static List<BoxShadow> cardMedium(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 4)),
        ]
      : const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
        ];

  static List<BoxShadow> cardStrong(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0xCC000000), blurRadius: 32, offset: Offset(0, 12)),
        ]
      : const [
          BoxShadow(color: Color(0x1F0F172A), blurRadius: 32, offset: Offset(0, 12)),
          BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 4)),
        ];

  static List<BoxShadow> popover(bool isDark) => isDark
      ? const [
          BoxShadow(color: Color(0xCC000000), blurRadius: 48, offset: Offset(0, 16)),
        ]
      : const [
          BoxShadow(color: Color(0x240F172A), blurRadius: 48, offset: Offset(0, 16)),
        ];
}
