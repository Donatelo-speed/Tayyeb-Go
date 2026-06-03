import 'package:flutter/material.dart';
import 'design_tokens.dart';

class TayyebGoTheme {
  TayyebGoTheme._();

  static Color get primaryColor => TayyebGoColors.primary;
  static const Color primaryDark = Color(0xFF00A86B);
  static Color get primaryLight => TayyebGoColors.primaryLight;
  static Color get primarySurface => TayyebGoColors.primarySurface;
  static Color get secondaryColor => TayyebGoColors.secondary;
  static Color get accentColor => TayyebGoColors.accent;

  static Color get surfaceColor => TayyebGoColors.surface;
  static Color get backgroundColor => TayyebGoColors.background;
  static Color get darkSurface => TayyebGoColors.darkSurface;
  static Color get darkBackground => TayyebGoColors.darkBg;

  static Color get textPrimary => TayyebGoColors.textPrimary;
  static Color get textSecondary => TayyebGoColors.textSecondary;
  static Color get textMuted => TayyebGoColors.textMuted;
  static Color get textOnDark => TayyebGoColors.textInverse;

  static Color get errorColor => TayyebGoColors.error;
  static Color get successColor => TayyebGoColors.success;
  static Color get warningColor => TayyebGoColors.warning;
  static Color get infoColor => TayyebGoColors.info;

  static Color get dividerColor => TayyebGoColors.divider;
  static Color get darkDivider => TayyebGoColors.darkDivider;

  static double get radiusXs => TayyebGoTokens.radiusXs;
  static double get radiusSm => TayyebGoTokens.radiusSm;
  static double get radiusMd => TayyebGoTokens.radiusMd;
  static double get radiusLg => TayyebGoTokens.radiusLg;
  static double get radiusXl => TayyebGoTokens.radiusXl;
  static double get radiusFull => TayyebGoTokens.radiusFull;

  static double get spaceXs => TayyebGoTokens.spaceXs;
  static double get spaceSm => TayyebGoTokens.spaceSm;
  static double get spaceMd => TayyebGoTokens.spaceMd;
  static double get spaceLg => TayyebGoTokens.spaceLg;
  static double get spaceXl => TayyebGoTokens.spaceXl;
  static double get space2xl => TayyebGoTokens.space2xl;
  static double get space3xl => TayyebGoTokens.space3xl;

  static List<BoxShadow> get cardShadow => TayyebGoTokens.cardShadow;
  static List<BoxShadow> get elevatedShadow => TayyebGoTokens.elevatedShadow;
  static List<BoxShadow> get modalShadow => TayyebGoTokens.modalShadow;

  static LinearGradient get primaryGradient => TayyebGoGradients.hero;
  static LinearGradient get accentGradient => TayyebGoGradients.accent;
  static LinearGradient get vibrantGradient => TayyebGoGradients.vibrant;

  static TextTheme get textTheme =>
      TayyebGoTokens.textTheme('Poppins');

  static InputDecorationTheme get inputDecoration => InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding:
            EdgeInsets.symmetric(horizontal: spaceLg, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: BorderSide(color: dividerColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: BorderSide(color: primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: BorderSide(color: errorColor)),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
      );

  static ElevatedButtonThemeData get elevatedButton => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm)),
          elevation: 0,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      );

  static OutlinedButtonThemeData get outlinedButton => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm)),
          side: BorderSide(color: primaryColor, width: 1.5),
          textStyle:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: dividerColor.withValues(alpha: 0.5)),
        boxShadow: cardShadow,
      );

  static BoxDecoration get primaryCardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
        boxShadow: elevatedShadow,
      );

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: elevatedShadow,
      );

  static AppBarTheme get appBarTheme => AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      );

  static NavigationBarThemeData get navigationBar => NavigationBarThemeData(
        elevation: 8,
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor);
          }
          return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: textMuted, size: 24);
        }),
      );

  static NavigationRailThemeData get navigationRail => NavigationRailThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: TextStyle(
            color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelTextStyle:
            TextStyle(color: textMuted, fontSize: 12),
        selectedIconTheme: IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: textMuted),
      );

  static ChipThemeData get chipTheme => ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withValues(alpha: 0.1),
        labelStyle:
            TextStyle(fontSize: 12, color: textSecondary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
            side: BorderSide.none),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );

  static BoxDecoration get bottomSheetDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radiusXl),
          topRight: Radius.circular(radiusXl),
        ),
        boxShadow: modalShadow,
      );

  static Widget buildDivider({double? indent, double? endIndent}) => Divider(
        color: dividerColor,
        thickness: 1,
        height: 1,
        indent: indent,
        endIndent: endIndent,
      );

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return warningColor;
      case 'accepted':
      case 'preparing':
        return infoColor;
      case 'ready_for_driver':
      case 'picked_up':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return successColor;
      case 'cancelled':
        return errorColor;
      default:
        return textMuted;
    }
  }
}