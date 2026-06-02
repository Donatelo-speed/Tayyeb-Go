import 'package:flutter/material.dart';

class TayyebGoTheme {
  TayyebGoTheme._();

  // ── Brand Colors ───────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF00A86B);
  static const Color primaryDark = Color(0xFF008C5A);
  static const Color primaryLight = Color(0xFF4CDB9A);
  static const Color secondaryColor = Color(0xFFE8F5E9);
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color darkSurface = Color(0xFF121212);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dividerColor = Color(0xFFE5E7EB);

  // ── Border Radius ──────────────────────────────────────────────────────
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ── Spacing ────────────────────────────────────────────────────────────
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2xl = 32.0;
  static const double space3xl = 40.0;

  // ── Elevation / Shadows ────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00A86B), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text Theme ─────────────────────────────────────────────────────────
  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.5,
        ),
      );

  // ── Input Decoration ───────────────────────────────────────────────────
  static InputDecorationTheme get inputDecoration => InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceLg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      );

  // ── Button Themes ──────────────────────────────────────────────────────
  static ElevatedButtonThemeData get elevatedButton => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          elevation: 0,
          shadowColor: primaryColor.withValues(alpha: 0.3),
        ),
      );

  static OutlinedButtonThemeData get outlinedButton => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          side: const BorderSide(color: primaryColor),
        ),
      );

  // ── Card Decoration ────────────────────────────────────────────────────
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

  // ── AppBar ─────────────────────────────────────────────────────────────
  static AppBarTheme get appBarTheme => const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );

  // ── Navigation Bar ─────────────────────────────────────────────────────
  static NavigationBarThemeData get navigationBar => NavigationBarThemeData(
        elevation: 8,
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      );

  // ── Navigation Rail ────────────────────────────────────────────────────
  static NavigationRailThemeData get navigationRail => NavigationRailThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: textMuted,
          fontSize: 12,
        ),
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: const IconThemeData(color: textMuted),
      );

  // ── Chip Theme ─────────────────────────────────────────────────────────
  static ChipThemeData get chipTheme => ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withValues(alpha: 0.1),
        labelStyle: const TextStyle(fontSize: 12, color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );

  // ── Bottom Sheet ───────────────────────────────────────────────────────
  static BoxDecoration get bottomSheetDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(radiusXl),
          topRight: Radius.circular(radiusXl),
        ),
        boxShadow: modalShadow,
      );

  // ── Divider ────────────────────────────────────────────────────────────
  static Widget buildDivider({double? indent, double? endIndent}) => Divider(
        color: dividerColor,
        thickness: 1,
        height: 1,
        indent: indent,
        endIndent: endIndent,
      );

  // ── Status Colors ──────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return warningColor;
      case 'accepted':
      case 'preparing':
        return const Color(0xFF3B82F6);
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
