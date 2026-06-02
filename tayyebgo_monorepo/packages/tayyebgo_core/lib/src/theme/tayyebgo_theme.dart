import 'package:flutter/material.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_spacing.dart';
import '../../presentation/theme/app_typography.dart';

class TayyebGoTheme {
  TayyebGoTheme._();

  static Color get primaryColor => AppColors.primary;
  static Color get successColor => AppColors.success;
  static Color get warningColor => AppColors.warning;
  static Color get errorColor => AppColors.error;
  static Color get surfaceColor => AppColors.surface;
  static Color get backgroundColor => AppColors.background;
  static Color get textPrimary => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get textMuted => AppColors.textMuted;
  static Color get dividerColor => AppColors.divider;
  static Color get cardBackground => AppColors.cardBackground;
  static Color get sidebarBg => AppColors.sidebarBg;

  static double get radiusSm => AppSpacing.radiusSm;
  static double get radiusMd => AppSpacing.radiusMd;
  static double get radiusLg => AppSpacing.radiusLg;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get elevatedCard => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusMd),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static TextStyle get hero => AppTypography.hero;
  static TextStyle get heading1 => AppTypography.heading1;
  static TextStyle get heading2 => AppTypography.heading2;
  static TextStyle get heading3 => AppTypography.heading3;

  static AppBarTheme get appBarTheme => AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      );

  static InputDecorationTheme get inputDecoration => InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      );

  static ElevatedButtonThemeData get elevatedButton => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      );
  static TextStyle get body => AppTypography.body;
  static TextStyle get caption => AppTypography.caption;
  static TextStyle get label => AppTypography.label;
  static TextStyle get statValue => AppTypography.statValue;

  static TextTheme get textTheme => TextTheme(
        displayLarge: hero,
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        bodyLarge: body,
        bodyMedium: AppTypography.bodyBold,
        bodySmall: caption,
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.small,
      );

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: _appBarTheme(false),
      inputDecorationTheme: _inputDecoration(false),
      elevatedButtonTheme: _elevatedButton,
      outlinedButtonTheme: _outlinedButton,
      navigationBarTheme: _navigationBarTheme(false),
      navigationRailTheme: _navigationRailTheme(false),
      chipTheme: _chipTheme(false),
      textTheme: textTheme,
      cardColor: surfaceColor,
      dividerColor: dividerColor,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: surfaceColor,
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DarkAppColors.primary,
        primary: DarkAppColors.primary,
        brightness: Brightness.dark,
        surface: DarkAppColors.surface,
        error: DarkAppColors.error,
      ),
      scaffoldBackgroundColor: DarkAppColors.background,
      appBarTheme: _appBarTheme(true),
      inputDecorationTheme: _inputDecoration(true),
      elevatedButtonTheme: _elevatedButton,
      outlinedButtonTheme: _outlinedButton,
      navigationBarTheme: _navigationBarTheme(true),
      navigationRailTheme: _navigationRailTheme(true),
      chipTheme: _chipTheme(true),
      textTheme: textTheme,
      cardColor: DarkAppColors.surface,
      dividerColor: DarkAppColors.divider,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DarkAppColors.surface,
        surfaceTintColor: DarkAppColors.surface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: DarkAppColors.surface,
        surfaceTintColor: DarkAppColors.surface,
      ),
    );
  }

  static AppBarTheme _appBarTheme(bool isDark) => AppBarTheme(
        backgroundColor: isDark ? DarkAppColors.surface : surfaceColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle:
            heading3.copyWith(color: isDark ? DarkAppColors.textPrimary : textPrimary),
        iconTheme: IconThemeData(
          color: isDark ? DarkAppColors.textPrimary : textPrimary,
        ),
      );

  static InputDecorationTheme _inputDecoration(bool isDark) {
    final c = isDark ? DarkAppColors.surfaceAlt : AppColors.surfaceAlt;
    final border = isDark ? DarkAppColors.divider : AppColors.divider;
    final label = isDark ? DarkAppColors.textSecondary : AppColors.textSecondary;
    return InputDecorationTheme(
      filled: true,
      fillColor: c,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(color: isDark ? DarkAppColors.primary : primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppTypography.label.copyWith(color: label),
      hintStyle: AppTypography.caption.copyWith(color: label),
    );
  }

  static final ElevatedButtonThemeData _elevatedButton = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      textStyle: AppTypography.button,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButton = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: BorderSide(color: primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    ),
  );

  static NavigationBarThemeData _navigationBarTheme(bool isDark) =>
      NavigationBarThemeData(
        backgroundColor: isDark ? DarkAppColors.surface : surfaceColor,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: (isDark ? DarkAppColors.primary : primaryColor)
            .withValues(alpha: 0.1),
      );

  static NavigationRailThemeData _navigationRailTheme(bool isDark) {
    final primary = isDark ? DarkAppColors.primary : primaryColor;
    final muted = isDark ? DarkAppColors.textMuted : textMuted;
    return NavigationRailThemeData(
      backgroundColor: isDark ? DarkAppColors.surface : surfaceColor,
      selectedIconTheme: IconThemeData(color: primary, size: 22),
      unselectedIconTheme: IconThemeData(color: muted, size: 20),
      selectedLabelTextStyle: TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: muted,
        fontSize: 12,
      ),
      indicatorColor: primary.withValues(alpha: 0.1),
    );
  }

  static ChipThemeData _chipTheme(bool isDark) {
    final primary = isDark ? DarkAppColors.primary : primaryColor;
    final divider = isDark ? DarkAppColors.divider : AppColors.divider;
    return ChipThemeData(
      backgroundColor: isDark ? DarkAppColors.surfaceAlt : surfaceColor,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle:
          AppTypography.caption.copyWith(color: isDark ? DarkAppColors.textPrimary : textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(color: divider),
    );
  }

  static Color get chipBackground => AppColors.surface.withValues(alpha: 0.8);
}
