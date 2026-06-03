import 'package:flutter/material.dart';
import 'admin_colors.dart';
import 'admin_spacing.dart';
import 'admin_typography.dart';

class AdminTheme {
  AdminTheme._();

  static ThemeData dark() {
    const d = true;
    return _base(d);
  }

  static ThemeData light() {
    const d = false;
    return _base(d);
  }

  static ThemeData _base(bool isDark) {
    final bg = AdminColors.bg(isDark);
    final card = AdminColors.card(isDark);
    final surface = AdminColors.surface(isDark);
    final border = AdminColors.border(isDark);
    final input = AdminColors.input(isDark);
    final textPrimary = AdminColors.textPrimary(isDark);
    final textSecondary = AdminColors.textSecondary(isDark);
    final textMuted = AdminColors.textMuted(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: AdminColors.primary,
        onPrimary: Colors.white,
        secondary: AdminColors.primaryLight,
        onSecondary: Colors.white,
        surface: card,
        onSurface: textPrimary,
        error: AdminColors.danger,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AdminTypography.h4(isDark),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadius.xl),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminRadius.lg),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminRadius.lg),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminRadius.lg),
          borderSide: const BorderSide(color: AdminColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)),
          textStyle: AdminTypography.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.primary,
          side: const BorderSide(color: AdminColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)),
          textStyle: AdminTypography.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AdminTypography.button,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AdminColors.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(fontSize: 12, color: textSecondary),
        secondaryLabelStyle: TextStyle(fontSize: 12, color: AdminColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.md)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 0),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return textMuted;
          if (s.contains(WidgetState.selected)) return AdminColors.primary;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AdminColors.primary.withValues(alpha: 0.25);
          return border;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AdminColors.primary,
        inactiveTrackColor: surface,
        thumbColor: AdminColors.primary,
        overlayColor: AdminColors.primary.withValues(alpha: 0.12),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadius.xxl),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AdminColors.primary,
        unselectedLabelColor: textMuted,
        indicatorColor: AdminColors.primary,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: card,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadius.lg),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AdminRadius.xxl),
            topRight: Radius.circular(AdminRadius.xxl),
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AdminColors.slate800 : AdminColors.slate900,
          borderRadius: BorderRadius.circular(AdminRadius.sm),
        ),
        textStyle: TextStyle(color: AdminColors.textPrimary(isDark)),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(isDark ? AdminColors.slate700 : AdminColors.slate300),
        radius: const Radius.circular(AdminRadius.full),
        thickness: WidgetStateProperty.all(6),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(card),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminRadius.lg),
            side: BorderSide(color: border, width: 0.5),
          )),
        ),
      ),

      iconTheme: IconThemeData(color: textSecondary),
      primaryIconTheme: IconThemeData(color: textPrimary),
    );
  }
}