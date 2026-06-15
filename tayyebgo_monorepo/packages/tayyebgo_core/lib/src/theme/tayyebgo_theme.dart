import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_shadow.dart';

class TayyebGoTheme {
  TayyebGoTheme._();

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

  static double get radiusSm => AppRadius.sm;
  static double get radiusMd => AppRadius.md;
  static double get radiusLg => AppRadius.lg;

  static AppBarTheme get appBarTheme => _appBarTheme(false);
  static InputDecorationTheme get inputDecoration => _inputDecoration(false);
  static ElevatedButtonThemeData get elevatedButton => _elevatedButton(false);
  static OutlinedButtonThemeData get outlinedButton => _outlinedButton(false);

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: divider),
        boxShadow: AppShadow.elevation1(true),
      );

  static BoxDecoration get elevatedCard => BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brCard,
        boxShadow: AppShadow.elevation2(true),
      );

  static TextStyle get hero => _textStyle(true, 42, FontWeight.w800, height: 1.06);
  static TextStyle get heading1 => _textStyle(true, 24, FontWeight.w700, height: 1.18);
  static TextStyle get heading2 => _textStyle(true, 18, FontWeight.w600, height: 1.28);
  static TextStyle get heading3 => _textStyle(true, 16, FontWeight.w600, height: 1.35);
  static TextStyle get body => _textStyle(true, 15, FontWeight.w400);
  static TextStyle get bodyBold => _textStyle(true, 15, FontWeight.w700);
  static TextStyle get caption => _textStyle(true, 13, FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get label => _textStyle(true, 12, FontWeight.w600, color: AppColors.textSecondary);
  static TextStyle get small => _textStyle(true, 11, FontWeight.w500, color: AppColors.textMuted);
  static TextStyle get button => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700);
  static TextStyle get statValue => GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800);
  static TextTheme get textTheme => _textTheme(true);

  static ThemeData darkTheme(BuildContext context) {
    return _theme(
      isDark: true,
      colors: _ThemePalette(
        primary: AppColors.primary,
        secondary: AppColors.route,
        tertiary: AppColors.partnerAccent,
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceAlt: AppColors.surfaceAlt,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        textMuted: AppColors.textMuted,
        border: AppColors.border,
        divider: AppColors.divider,
        error: AppColors.error,
      ),
    );
  }

  static ThemeData lightTheme(BuildContext context) {
    return _theme(
      isDark: false,
      colors: _ThemePalette(
        primary: LightAppColors.primary,
        secondary: LightAppColors.route,
        tertiary: LightAppColors.partnerAccent,
        background: LightAppColors.background,
        surface: LightAppColors.surface,
        surfaceAlt: LightAppColors.surfaceAlt,
        textPrimary: LightAppColors.textPrimary,
        textSecondary: LightAppColors.textSecondary,
        textMuted: LightAppColors.textMuted,
        border: LightAppColors.border,
        divider: LightAppColors.divider,
        error: LightAppColors.error,
      ),
    );
  }

  static ThemeData _theme({
    required bool isDark,
    required _ThemePalette colors,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      primary: colors.primary,
      secondary: colors.secondary,
      tertiary: colors.tertiary,
      surface: colors.surface,
      error: colors.error,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: _textTheme(isDark),
      primaryTextTheme: _textTheme(isDark),
      cardColor: colors.surface,
      dividerColor: colors.divider,
      appBarTheme: _appBarTheme(isDark),
      inputDecorationTheme: _inputDecoration(isDark),
      elevatedButtonTheme: _elevatedButton(isDark),
      outlinedButtonTheme: _outlinedButton(isDark),
      textButtonTheme: _textButton(isDark),
      navigationBarTheme: _navigationBarTheme(isDark),
      navigationRailTheme: _navigationRailTheme(isDark),
      chipTheme: _chipTheme(isDark),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBottomSheet),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceAlt : LightAppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: BorderSide(color: colors.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
        iconColor: colors.textMuted,
        textColor: colors.textPrimary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textMuted,
        indicatorColor: colors.primary,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final primary = isDark ? AppColors.textPrimary : LightAppColors.textPrimary;
    final secondary = isDark ? AppColors.textSecondary : LightAppColors.textSecondary;
    final muted = isDark ? AppColors.textMuted : LightAppColors.textMuted;
    return TextTheme(
      displayLarge: _textStyle(isDark, 42, FontWeight.w800, color: primary, height: 1.06),
      displayMedium: _textStyle(isDark, 34, FontWeight.w800, color: primary, height: 1.1),
      displaySmall: _textStyle(isDark, 28, FontWeight.w700, color: primary, height: 1.15),
      headlineLarge: _textStyle(isDark, 24, FontWeight.w700, color: primary, height: 1.18),
      headlineMedium: _textStyle(isDark, 20, FontWeight.w700, color: primary, height: 1.25),
      headlineSmall: _textStyle(isDark, 18, FontWeight.w600, color: primary, height: 1.3),
      titleLarge: _textStyle(isDark, 18, FontWeight.w700, color: primary, height: 1.3),
      titleMedium: _textStyle(isDark, 16, FontWeight.w600, color: primary, height: 1.35),
      titleSmall: _textStyle(isDark, 14, FontWeight.w600, color: secondary, height: 1.35),
      bodyLarge: _textStyle(isDark, 16, FontWeight.w400, color: primary),
      bodyMedium: _textStyle(isDark, 14, FontWeight.w400, color: primary),
      bodySmall: _textStyle(isDark, 12, FontWeight.w400, color: secondary, height: 1.4),
      labelLarge: _textStyle(isDark, 14, FontWeight.w700, color: primary, height: 1.3),
      labelMedium: _textStyle(isDark, 12, FontWeight.w600, color: secondary, height: 1.3),
      labelSmall: _textStyle(isDark, 11, FontWeight.w600, color: muted, height: 1.25),
    );
  }

  static TextStyle _textStyle(
    bool isDark,
    double size,
    FontWeight weight, {
    Color? color,
    double height = 1.45,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? (isDark ? AppColors.textPrimary : LightAppColors.textPrimary),
      height: height,
      letterSpacing: 0,
    );
  }

  static AppBarTheme _appBarTheme(bool isDark) {
    final bg = isDark ? AppColors.background : LightAppColors.background;
    final fg = isDark ? AppColors.textPrimary : LightAppColors.textPrimary;
    return AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: fg,
        letterSpacing: 0,
      ),
      iconTheme: IconThemeData(color: fg),
    );
  }

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

  static ElevatedButtonThemeData _elevatedButton(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.primary : LightAppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButton(bool isDark) {
    final primary = isDark ? AppColors.primary : LightAppColors.primary;
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  static TextButtonThemeData _textButton(bool isDark) {
    final primary = isDark ? AppColors.primary : LightAppColors.primary;
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(bool isDark) {
    final primary = isDark ? AppColors.primary : LightAppColors.primary;
    final surface = isDark ? AppColors.surface : LightAppColors.surface;
    final muted = isDark ? AppColors.textMuted : LightAppColors.textMuted;
    return NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          color: selected ? primary : muted,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? primary : muted, size: 22);
      }),
    );
  }

  static NavigationRailThemeData _navigationRailTheme(bool isDark) {
    final primary = isDark ? AppColors.primary : LightAppColors.primary;
    final surface = isDark ? AppColors.surface : LightAppColors.surface;
    final muted = isDark ? AppColors.textMuted : LightAppColors.textMuted;
    return NavigationRailThemeData(
      backgroundColor: surface,
      selectedIconTheme: IconThemeData(color: primary, size: 22),
      unselectedIconTheme: IconThemeData(color: muted, size: 20),
      selectedLabelTextStyle: GoogleFonts.inter(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: muted,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      indicatorColor: primary.withValues(alpha: 0.14),
    );
  }

  static ChipThemeData _chipTheme(bool isDark) {
    final primary = isDark ? AppColors.primary : LightAppColors.primary;
    final divider = isDark ? AppColors.border : LightAppColors.border;
    final bg = isDark ? AppColors.surfaceAlt : LightAppColors.surfaceAlt;
    final text = isDark ? AppColors.textPrimary : LightAppColors.textPrimary;
    return ChipThemeData(
      backgroundColor: bg,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brChip),
      side: BorderSide(color: divider),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ThemePalette {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color error;

  const _ThemePalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.error,
  });
}
