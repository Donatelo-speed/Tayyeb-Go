import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Extreme weight variation typography — Inter font.
/// Headers: thin/light. Numbers: bold/black. Body: regular.
abstract class AppTypography {
  static TextStyle _inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.5,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ── Display (Thin headers — premium feel) ──
  static TextStyle get displayLarge => _inter(
        fontSize: 44,
        fontWeight: FontWeight.w200,  // Ultra-thin for premium
        height: 1.05,
        letterSpacing: 0,
      );

  static TextStyle get displayMedium => _inter(
        fontSize: 36,
        fontWeight: FontWeight.w200,
        height: 1.1,
        letterSpacing: 0,
      );

  static TextStyle get displaySmall => _inter(
        fontSize: 28,
        fontWeight: FontWeight.w300,  // Thin
        height: 1.15,
        letterSpacing: 0,
      );

  // ── Title (Light to Regular — still premium) ──
  static TextStyle get titleLarge => _inter(
        fontSize: 24,
        fontWeight: FontWeight.w300,  // Light
        height: 1.2,
        letterSpacing: 0,
      );

  static TextStyle get titleMedium => _inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,  // Regular
        height: 1.3,
      );

  static TextStyle get titleSmall => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,  // Medium
        height: 1.35,
      );

  // ── Body (Regular) ──
  static TextStyle get bodyLarge => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ── Label (Medium weight for buttons/labels) ──
  static TextStyle get labelLarge => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0,
      );

  static TextStyle get labelMedium => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get labelSmall => _inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0,
      );

  // ── Overline (uppercase, spaced) ──
  static TextStyle get overline => _inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0,
        color: AppColors.textMuted,
      );

  // ── Caption ──
  static TextStyle get caption => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get captionBold => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ── Button ──
  static TextStyle get button => _inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textInverse,
        letterSpacing: 0,
      );

  // ── Stat (Bold numbers — contrast with thin headers) ──
  static TextStyle get statValue => _inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,  // Extra bold for numbers
        letterSpacing: 0,
      );

  static TextStyle get statLabel => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,  // Regular, not medium
        color: AppColors.textMuted,
        height: 1.3,
      );

  // ── Earnings (Bold for money) ──
  static TextStyle get earningsValue => _inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      );

  // ── Price (Medium for item prices) ──
  static TextStyle get price => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  // ── Backward compatibility aliases ──
  static TextStyle get hero => displayLarge;
  static TextStyle get heading1 => titleLarge;
  static TextStyle get heading2 => titleMedium;
  static TextStyle get heading3 => titleSmall;
  static TextStyle get body => bodyMedium;
  static TextStyle get bodyBold => bodyMedium.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get small => labelSmall;
  static TextStyle get label => labelMedium;
}
