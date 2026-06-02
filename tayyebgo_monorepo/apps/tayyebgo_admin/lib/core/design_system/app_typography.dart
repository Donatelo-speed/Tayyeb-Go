import 'package:flutter/material.dart';

abstract class AppTypography {
  static const _family = 'Inter';

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w700,
  );

  static const heading1 = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 1.33,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w700,
  );

  static const heading2 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static const heading3 = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  static const subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
  );

  static const bodyBold = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w600,
  );

  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
  );

  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    height: 1.45,
    letterSpacing: 0.4,
    fontWeight: FontWeight.w600,
  );

  static const number = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 1.14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const numberLarge = TextStyle(
    fontFamily: _family,
    fontSize: 36,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static TextTheme toTextTheme(Color textPrimary, Color textSecondary, Color textMuted) {
    return TextTheme(
      displayLarge: display.copyWith(color: textPrimary),
      displayMedium: display.copyWith(color: textPrimary, fontSize: 28),
      headlineLarge: heading1.copyWith(color: textPrimary),
      headlineMedium: heading2.copyWith(color: textPrimary),
      headlineSmall: heading3.copyWith(color: textPrimary),
      titleLarge: heading2.copyWith(color: textPrimary),
      titleMedium: heading3.copyWith(color: textPrimary),
      titleSmall: subtitle.copyWith(color: textPrimary),
      bodyLarge: body.copyWith(color: textPrimary),
      bodyMedium: body.copyWith(color: textSecondary),
      bodySmall: caption.copyWith(color: textMuted),
      labelLarge: bodyBold.copyWith(color: textPrimary),
      labelMedium: label.copyWith(color: textSecondary),
      labelSmall: label.copyWith(color: textMuted),
    );
  }
}
