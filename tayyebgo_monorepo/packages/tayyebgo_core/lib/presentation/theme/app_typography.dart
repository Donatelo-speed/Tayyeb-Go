import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TayyebGo unified typography system.
///
/// Dual-font pairing: Hanken Grotesk for display/headings, Inter for body/labels.
/// All styles are color-agnostic — callers or theme context set the color.
abstract class AppTypography {
  // ══════════════════════════════════════════════════════════════════════════
  // DISPLAY / HEADING (Hanken Grotesk)
  // ══════════════════════════════════════════════════════════════════════════

  static TextStyle _hanken({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.hankenGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get displayLarge => _hanken(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.5,
      );

  static TextStyle get displayMedium => _hanken(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1,
      );

  static TextStyle get displaySmall => _hanken(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.75,
      );

  static TextStyle get headlineLarge => _hanken(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => _hanken(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle get headlineSmall => _hanken(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get heading3 => _hanken(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // BODY / LABEL (Inter)
  // ══════════════════════════════════════════════════════════════════════════

  static TextStyle _inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.45,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get titleLarge => _hanken(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get titleMedium => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get titleSmall => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get bodyLarge => _inter(fontSize: 16, height: 1.55);
  static TextStyle get bodyMedium => _inter(fontSize: 14, height: 1.5);
  static TextStyle get bodySmall => _inter(fontSize: 12, height: 1.4);

  /// Backward-compat alias for [bodyMedium].
  static TextStyle get body => bodyMedium;

  /// Bold variant of [bodyMedium].
  static TextStyle get bodyBold => bodyMedium.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get labelLarge => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );

  static TextStyle get labelMedium => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get labelSmall => _inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  /// Backward-compat alias for [labelSmall].
  static TextStyle get label => labelSmall;

  // ══════════════════════════════════════════════════════════════════════════
  // SPECIALTY STYLES (color-agnostic)
  // ══════════════════════════════════════════════════════════════════════════

  static TextStyle get overline => _inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.8,
      );

  static TextStyle get caption => _inter(
        fontSize: 12,
        height: 1.4,
      );

  static TextStyle get captionBold => caption.copyWith(fontWeight: FontWeight.w700);

  static TextStyle get button => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get statValue => _inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.05,
      );

  static TextStyle get statLabel => _inter(
        fontSize: 12,
        height: 1.3,
      );

  static TextStyle get earningsValue => _inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.05,
      );

  static TextStyle get price => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // MATHEMATIC TEXT THEME (for ThemeData integration)
  // ══════════════════════════════════════════════════════════════════════════

  static TextTheme toTextTheme({
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    Color? accentColor,
  }) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: textPrimary),
      displayMedium: displayMedium.copyWith(color: textPrimary),
      displaySmall: displaySmall.copyWith(color: textPrimary),
      headlineLarge: headlineLarge.copyWith(color: textPrimary),
      headlineMedium: headlineMedium.copyWith(color: textPrimary),
      headlineSmall: headlineSmall.copyWith(color: textPrimary),
      titleLarge: titleLarge.copyWith(color: textPrimary),
      titleMedium: titleMedium.copyWith(color: textPrimary),
      titleSmall: titleSmall.copyWith(color: accentColor ?? textSecondary),
      bodyLarge: bodyLarge.copyWith(color: textPrimary),
      bodyMedium: bodyMedium.copyWith(color: textPrimary),
      bodySmall: bodySmall.copyWith(color: textSecondary),
      labelLarge: labelLarge.copyWith(color: textPrimary),
      labelMedium: labelMedium.copyWith(color: textSecondary),
      labelSmall: labelSmall.copyWith(color: textMuted),
    );
  }
}
