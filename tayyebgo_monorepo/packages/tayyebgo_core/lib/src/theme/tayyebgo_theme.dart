import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_shadow.dart';

/// TayyebGoTheme — Dark-first design system.
/// Default: dark mode. Light mode available via toggle.
class TayyebGoTheme {
  TayyebGoTheme._();

  // ─── Base color getters (dark-first) ──────────────────────
  static Color get primary => AppColors.primary;
  static Color get success => AppColors.success;
  static Color get warning => AppColors.warning;
  static Color get error => AppColors.error;
  static Color get surface => AppColors.surface;
  static Color get background => AppColors.background;
  static Color get textPrimary => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get textMuted => AppColors.textMuted;
  static Color get divider => AppColors.divider;
  static Color get cardBackground => surface;

  // ─── Backward-compat color getters (used by existing screens) ─
  static Color get primaryColor => primary;
  static Color get successColor => success;
  static Color get warningColor => warning;
  static Color get errorColor => error;
  static Color get surfaceColor => surface;
  static Color get backgroundColor => background;
  static Color get textPrimaryColor => textPrimary;
  static Color get textSecondaryColor => textSecondary;
  static Color get textMutedColor => textMuted;
  static Color get dividerColor => divider;

  // ─── Convenience radius getters ─────────────────────────────
  static double get radiusSm => AppRadius.sm;
  static double get radiusMd => AppRadius.md;
  static double get radiusLg => AppRadius.lg;

  // ─── Backward-compat public component themes ────────────────
  static AppBarTheme get appBarTheme => _appBarTheme(false);
  static InputDecorationTheme get inputDecoration => _inputDecoration(false);
  static ElevatedButtonThemeData get elevatedButton => _elevatedButton;
  static OutlinedButtonThemeData get outlinedButton => _outlinedButton;

  // ─── Reusable box decorations ───────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: divider),
        boxShadow: AppShadow.elevation1(false),
      );

  static BoxDecoration get elevatedCard => BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brCard,
        boxShadow: AppShadow.elevation2(false),
      );

  // ─── Text styles ──────────────────────────────────────────
  static TextStyle get hero => GoogleFonts.inter(
        fontSize: 44,
        fontWeight: FontWeight.w200,
        letterSpacing: 0,
        color: textPrimary,
      );
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
        color: textPrimary,
      );
  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textPrimary,
      );
  static TextStyle get heading3 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );
  static TextStyle get bodyBold => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: textSecondary,
      );
  static TextStyle get small => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get statValue => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      );

  // ─── Full TextTheme ─────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        displayLarge: hero,
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        bodyLarge: body,
        bodyMedium: bodyBold,
        bodySmall: caption,
        labelLarge: button,
        labelMedium: label,
        labelSmall: small,
      );

  // ─── Dark Theme (default) ──────────────────────────────────
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      cardColor: AppColors.surface,
      dividerColor: AppColors.divider,
      appBarTheme: _appBarTheme(true),
      inputDecorationTheme: _inputDecoration(true),
      elevatedButtonTheme: _elevatedButton,
      outlinedButtonTheme: _outlinedButton,
      textButtonTheme: _textButton,
      navigationBarTheme: _navigationBarTheme(true),
      navigationRailTheme: _navigationRailTheme(true),
      chipTheme: _chipTheme(true),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
      ),
    );
  }

  // ─── Light Theme ────────────────────────────────────────────
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LightAppColors.primary,
        primary: LightAppColors.primary,
        brightness: Brightness.light,
        error: LightAppColors.error,
      ),
      scaffoldBackgroundColor: LightAppColors.background,
      textTheme: textTheme,
      cardColor: LightAppColors.surface,
      dividerColor: LightAppColors.divider,
      appBarTheme: _appBarTheme(false),
      inputDecorationTheme: _inputDecoration(false),
      elevatedButtonTheme: _elevatedButton,
      outlinedButtonTheme: _outlinedButton,
      textButtonTheme: _textButton,
      navigationBarTheme: _navigationBarTheme(false),
      navigationRailTheme: _navigationRailTheme(false),
      chipTheme: _chipTheme(false),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: LightAppColors.surface,
        surfaceTintColor: LightAppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: LightAppColors.surface,
        surfaceTintColor: LightAppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LightAppColors.surface,
        surfaceTintColor: LightAppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LightAppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: LightAppColors.textInverse, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: LightAppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: const BorderSide(color: LightAppColors.divider),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: LightAppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
      ),
    );
  }

  // ─── Component Themes (private helpers) ─────────────────────
  static AppBarTheme _appBarTheme(bool isDark) => AppBarTheme(
        backgroundColor: isDark ? AppColors.surface : LightAppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimary : LightAppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimary : LightAppColors.textPrimary,
        ),
      );

  static InputDecorationTheme _inputDecoration(bool isDark) {
    final fillColor = isDark ? AppColors.surfaceAlt : LightAppColors.surfaceAlt;
    final borderColor = isDark ? AppColors.border : LightAppColors.border;
    final focusColor = isDark ? AppColors.primary : LightAppColors.primary;
    final labelColor = isDark ? AppColors.textMuted : LightAppColors.textMuted;
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: BorderSide(color: focusColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: GoogleFonts.inter(fontSize: 14, color: labelColor),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: labelColor),
    );
  }

  static final _elevatedButton = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  );

  static final _outlinedButton = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  );

  static final _textButton = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  );

  static NavigationBarThemeData _navigationBarTheme(bool isDark) =>
      NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surface : LightAppColors.surface,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: (isDark ? AppColors.primary : LightAppColors.primary)
            .withValues(alpha: 0.12),
      );

  static NavigationRailThemeData _navigationRailTheme(bool isDark) {
    final primaryColor = isDark ? AppColors.primary : LightAppColors.primary;
    final muted = isDark ? AppColors.textMuted : LightAppColors.textMuted;
    return NavigationRailThemeData(
      backgroundColor: isDark ? AppColors.surface : LightAppColors.surface,
      selectedIconTheme: IconThemeData(color: primaryColor, size: 22),
      unselectedIconTheme: IconThemeData(color: muted, size: 20),
      selectedLabelTextStyle: GoogleFonts.inter(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: muted,
        fontSize: 12,
      ),
      indicatorColor: primaryColor.withValues(alpha: 0.12),
    );
  }

  static ChipThemeData _chipTheme(bool isDark) {
    final primaryColor = isDark ? AppColors.primary : LightAppColors.primary;
    final divider = isDark ? AppColors.border : LightAppColors.border;
    final bg = isDark ? AppColors.surfaceAlt : LightAppColors.surfaceAlt;
    final textColor = isDark ? AppColors.textPrimary : LightAppColors.textPrimary;
    return ChipThemeData(
      backgroundColor: bg,
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        color: textColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brChip,
      ),
      side: BorderSide(color: divider),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}
