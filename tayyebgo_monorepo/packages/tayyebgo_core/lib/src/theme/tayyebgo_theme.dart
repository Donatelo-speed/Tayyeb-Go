import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_shadow.dart';
import '../../presentation/theme/app_typography.dart';

/// TayyebGo unified theme builder.
///
/// Single source of truth for all Material 3 ThemeData across all apps.
/// Uses AppColors, AppTypography, AppRadius, and AppShadow tokens.
class TayyebGoTheme {
  TayyebGoTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // BACKWARD-COMPATIBLE STATIC GETTERS (dark theme defaults)
  // ══════════════════════════════════════════════════════════════════════════

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

  static TextStyle get hero => AppTypography.displayLarge;
  static TextStyle get heading1 => AppTypography.headlineLarge;
  static TextStyle get heading2 => AppTypography.headlineMedium;
  static TextStyle get heading3 => AppTypography.headlineSmall;
  static TextStyle get body => AppTypography.bodyMedium;
  static TextStyle get bodyBold => AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700);
  static TextStyle get caption => AppTypography.caption;
  static TextStyle get label => AppTypography.labelMedium;
  static TextStyle get small => AppTypography.labelSmall;
  static TextStyle get button => AppTypography.button;
  static TextStyle get statValue => AppTypography.statValue;

  static TextTheme get textTheme => AppTypography.toTextTheme(
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        textMuted: AppColors.textMuted,
      );

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

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData darkTheme() {
    const colors = _DarkPalette();
    return _buildTheme(isDark: true, colors: colors);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData lightTheme() {
    const colors = _LightPalette();
    return _buildTheme(isDark: false, colors: colors);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // THEME BUILDER
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData _buildTheme({
    required bool isDark,
    required _ThemePalette colors,
  }) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: colors.primary,
      onPrimary: Colors.white,
      primaryContainer: colors.primarySoft,
      onPrimaryContainer: colors.primary,
      secondary: colors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: colors.secondarySoft,
      onSecondaryContainer: colors.secondary,
      tertiary: colors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: colors.tertiarySoft,
      onTertiaryContainer: colors.tertiary,
      error: colors.error,
      onError: Colors.white,
      errorContainer: colors.errorSoft,
      onErrorContainer: colors.error,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainer: colors.surfaceAlt,
      surfaceContainerHighest: colors.surfaceElevated,
      outline: colors.border,
      outlineVariant: colors.divider,
      shadow: Colors.black,
    );

    final textTheme = AppTypography.toTextTheme(
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
      textMuted: colors.textMuted,
      accentColor: colors.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardColor: colors.surface,
      dividerColor: colors.divider,
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: colors.textMuted),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: colors.textMuted),
      ),
      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      // ── Navigation Bar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: selected ? colors.primary : colors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.textMuted,
            size: 22,
          );
        }),
      ),
      // ── Navigation Rail ──
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        selectedIconTheme: IconThemeData(color: colors.primary, size: 22),
        unselectedIconTheme: IconThemeData(color: colors.textMuted, size: 20),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: colors.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        indicatorColor: colors.primary.withValues(alpha: 0.14),
      ),
      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceAlt,
        selectedColor: colors.primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brChip),
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      // ── Card ──
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
      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceAlt : colors.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: isDark ? colors.textPrimary : colors.surface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        behavior: SnackBarBehavior.floating,
      ),
      // ── Tab Bar ──
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textMuted,
        indicatorColor: colors.primary,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
      ),
      // ── List Tile ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
        iconColor: colors.textMuted,
        textColor: colors.textPrimary,
      ),
      // ── Popup Menu ──
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      ),
      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.surfaceAlt;
        }),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
      ),
      // ── Radio ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.textMuted;
        }),
      ),
      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return colors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.surfaceAlt;
        }),
      ),
      // ── Slider ──
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.surfaceAlt,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.1),
      ),
      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: AppRadius.brMd,
        ),
        textStyle: GoogleFonts.inter(
          color: colors.background,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ── Progress Indicator ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceAlt,
      ),
      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// THEME PALETTES
// ════════════════════════════════════════════════════════════════════════════

abstract class _ThemePalette {
  Color get primary;
  Color get primarySoft;
  Color get secondary;
  Color get secondarySoft;
  Color get tertiary;
  Color get tertiarySoft;
  Color get background;
  Color get surface;
  Color get surfaceAlt;
  Color get surfaceElevated;
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get border;
  Color get divider;
  Color get error;
  Color get errorSoft;
}

class _DarkPalette implements _ThemePalette {
  const _DarkPalette();

  @override Color get primary => AppColors.primary;
  @override Color get primarySoft => AppColors.primarySoft;
  @override Color get secondary => AppColors.route;
  @override Color get secondarySoft => AppColors.routeSoft;
  @override Color get tertiary => AppColors.partnerAccent;
  @override Color get tertiarySoft => AppColors.partnerAccent.withValues(alpha: 0.15);
  @override Color get background => AppColors.background;
  @override Color get surface => AppColors.surface;
  @override Color get surfaceAlt => AppColors.surfaceAlt;
  @override Color get surfaceElevated => AppColors.surfaceElevated;
  @override Color get textPrimary => AppColors.textPrimary;
  @override Color get textSecondary => AppColors.textSecondary;
  @override Color get textMuted => AppColors.textMuted;
  @override Color get border => AppColors.border;
  @override Color get divider => AppColors.divider;
  @override Color get error => AppColors.error;
  @override Color get errorSoft => AppColors.errorSoft;
}

class _LightPalette implements _ThemePalette {
  const _LightPalette();

  @override Color get primary => LightAppColors.primary;
  @override Color get primarySoft => LightAppColors.primarySoft;
  @override Color get secondary => LightAppColors.route;
  @override Color get secondarySoft => LightAppColors.routeSoft;
  @override Color get tertiary => LightAppColors.partnerAccent;
  @override Color get tertiarySoft => LightAppColors.partnerAccent.withValues(alpha: 0.15);
  @override Color get background => LightAppColors.background;
  @override Color get surface => LightAppColors.surface;
  @override Color get surfaceAlt => LightAppColors.surfaceAlt;
  @override Color get surfaceElevated => LightAppColors.surfaceElevated;
  @override Color get textPrimary => LightAppColors.textPrimary;
  @override Color get textSecondary => LightAppColors.textSecondary;
  @override Color get textMuted => LightAppColors.textMuted;
  @override Color get border => LightAppColors.border;
  @override Color get divider => LightAppColors.divider;
  @override Color get error => LightAppColors.error;
  @override Color get errorSoft => LightAppColors.errorSoft;
}
