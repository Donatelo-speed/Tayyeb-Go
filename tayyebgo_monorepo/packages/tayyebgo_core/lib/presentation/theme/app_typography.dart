import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTypography {
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
      color: color ?? AppColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get displayLarge => _inter(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        height: 1.06,
      );

  static TextStyle get displayMedium => _inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
      );

  static TextStyle get displaySmall => _inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.15,
      );

  static TextStyle get titleLarge => _inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.18,
      );

  static TextStyle get titleMedium => _inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.28,
      );

  static TextStyle get titleSmall => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get bodyLarge => _inter(fontSize: 16, height: 1.55);
  static TextStyle get bodyMedium => _inter(fontSize: 14, height: 1.5);
  static TextStyle get bodySmall => _inter(fontSize: 12, height: 1.4);

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

  static TextStyle get overline => _inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textMuted,
      );

  static TextStyle get caption => _inter(
        fontSize: 12,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get captionBold => caption.copyWith(fontWeight: FontWeight.w700);

  static TextStyle get button => _inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textInverse,
      );

  static TextStyle get statValue => _inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.05,
      );

  static TextStyle get statLabel => _inter(
        fontSize: 12,
        color: AppColors.textMuted,
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

  static TextStyle get hero => displayLarge;
  static TextStyle get heading1 => titleLarge;
  static TextStyle get heading2 => titleMedium;
  static TextStyle get heading3 => titleSmall;
  static TextStyle get body => bodyMedium;
  static TextStyle get bodyBold => bodyMedium.copyWith(fontWeight: FontWeight.w700);
  static TextStyle get small => labelSmall;
  static TextStyle get label => labelMedium;
}
