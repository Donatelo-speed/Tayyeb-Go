export 'design/design.dart';

import 'package:flutter/material.dart';

@Deprecated('Use AdminColors from design/design.dart')
class AdminColors {
  AdminColors._();
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFFA5B4FC);
  static const secondary = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const bgDark = Color(0xFF0B1121);
  static const bgDarkCard = Color(0xFF151D30);
  static const bgDarkSurface = Color(0xFF1E293B);
  static const bgDarkHover = Color(0xFF263348);
  static const bgDarkInput = Color(0xFF0F1A2E);
  static const bgLight = Color(0xFFF8FAFC);
  static const bgLightCard = Color(0xFFFFFFFF);
  static const bgLightSurface = Color(0xFFF1F5F9);
  static const bgLightHover = Color(0xFFE2E8F0);
  static const bgLightInput = Color(0xFFF1F5F9);
  static const textDarkPrimary = Color(0xFFF1F5F9);
  static const textDarkSecondary = Color(0xFF94A3B8);
  static const textDarkMuted = Color(0xFF64748B);
  static const textDarkOnPrimary = Color(0xFFFFFFFF);
  static const textLightPrimary = Color(0xFF0F172A);
  static const textLightSecondary = Color(0xFF475569);
  static const textLightMuted = Color(0xFF94A3B8);
  static const textLightOnPrimary = Color(0xFFFFFFFF);
  static const borderDark = Color(0xFF1E293B);
  static const borderLight = Color(0xFFE2E8F0);
  static const dividerDark = Color(0xFF263348);
  static const dividerLight = Color(0xFFE2E8F0);
  static const skeletonDark = Color(0xFF1E293B);
  static const skeletonDarkShine = Color(0xFF263348);
  static const skeletonLight = Color(0xFFE2E8F0);
  static const skeletonLightShine = Color(0xFFF1F5F9);
  static const scrollbarDark = Color(0xFF263348);
  static const scrollbarLight = Color(0xFFCBD5E1);
  static List<Color> roleColors(String role) {
    switch (role) {
      case 'superAdmin': return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'restaurantOwner': return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case 'cashier': return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case 'driver': return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'customer': return [const Color(0xFF10B981), const Color(0xFF059669)];
      default: return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
    }
  }
  static Color statusColor(String status) {
    switch (status) {
      case 'pending': return warning;
      case 'accepted': return info;
      case 'preparing': return secondary;
      case 'ready_for_driver': return const Color(0xFF06B6D4);
      case 'picked_up': return const Color(0xFFF97316);
      case 'delivered': return success;
      case 'cancelled': return danger;
      case 'open': return info;
      case 'assigned': return secondary;
      case 'in_progress': return const Color(0xFF8B5CF6);
      case 'resolved': return success;
      case 'closed': return const Color(0xFF94A3B8);
      default: return const Color(0xFF94A3B8);
    }
  }
}

@Deprecated('Use AdminSpacing from design/design.dart')
class AdminSpacing {
  AdminSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

@Deprecated('Use AdminRadius from design/design.dart')
class AdminRadius {
  AdminRadius._();
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double full = 999;
}

@Deprecated('Use AdminShadows from design/design.dart')
class AdminShadows {
  AdminShadows._();
  static List<BoxShadow> card(bool isDark) => [
    BoxShadow(color: isDark ? const Color(0x0A000000) : const Color(0x08000000), blurRadius: 4, offset: const Offset(0, 1)),
    BoxShadow(color: isDark ? const Color(0x1A000000) : const Color(0x0F000000), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> elevated(bool isDark) => [
    BoxShadow(color: isDark ? const Color(0x1A000000) : const Color(0x0F000000), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: isDark ? const Color(0x33000000) : const Color(0x1A000000), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> topBar = [
    const BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static List<BoxShadow> none = [];
}

@Deprecated('Use AdminTypography from design/design.dart')
class AdminTypography {
  AdminTypography._();
  static const fontFamily = 'Inter';
  static const fontFamilyMono = 'JetBrains Mono';
  static TextStyle h1(bool isDark) => TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary, fontFamily: fontFamily, letterSpacing: -0.5, height: 1.1);
  static TextStyle h2(bool isDark) => TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary, fontFamily: fontFamily, letterSpacing: -0.3, height: 1.2);
  static TextStyle h3(bool isDark) => TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary, fontFamily: fontFamily, height: 1.3);
  static TextStyle h4(bool isDark) => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary, fontFamily: fontFamily, height: 1.4);
  static TextStyle body(bool isDark) => TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary, fontFamily: fontFamily, height: 1.5);
  static TextStyle bodySmall(bool isDark) => TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary, fontFamily: fontFamily, height: 1.4);
  static TextStyle caption(bool isDark) => TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: isDark ? AdminColors.textDarkMuted : AdminColors.textLightMuted, fontFamily: fontFamily, height: 1.3);
  static TextStyle label(bool isDark) => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary, fontFamily: fontFamily, letterSpacing: 0.5);
  static TextStyle mono(bool isDark) => TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary, fontFamily: fontFamilyMono);
  static TextStyle buttonText = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontFamily, letterSpacing: 0.2);
  static TextStyle kpiValue(bool isDark) => TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary, fontFamily: fontFamily, letterSpacing: -0.5);
  static TextStyle kpiLabel(bool isDark) => TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary, fontFamily: fontFamily);
}

@Deprecated('Use AdminTheme from design/design.dart')
class AdminTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.bgDark,
      colorScheme: const ColorScheme.dark(primary: AdminColors.primary, secondary: AdminColors.secondary, surface: AdminColors.bgDarkCard, error: AdminColors.danger),
      fontFamily: AdminTypography.fontFamily,
      appBarTheme: AppBarTheme(backgroundColor: AdminColors.bgDark, elevation: 0, centerTitle: false, titleTextStyle: AdminTypography.h4(true), iconTheme: const IconThemeData(color: AdminColors.textDarkPrimary)),
      cardTheme: CardThemeData(color: AdminColors.bgDarkCard, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xl))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AdminColors.bgDarkInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide(color: AdminColors.borderDark)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: const BorderSide(color: AdminColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), hintStyle: const TextStyle(color: AdminColors.textDarkMuted), labelStyle: const TextStyle(color: AdminColors.textDarkSecondary)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)), textStyle: AdminTypography.buttonText)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: AdminColors.primary, side: const BorderSide(color: AdminColors.primary), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)))),
      chipTheme: ChipThemeData(backgroundColor: AdminColors.bgDarkSurface, selectedColor: AdminColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.md)), labelStyle: const TextStyle(fontSize: 11, color: AdminColors.textDarkSecondary), side: BorderSide.none),
      dividerTheme: const DividerThemeData(color: AdminColors.dividerDark, thickness: 1, space: 1),
      scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStateProperty.all(AdminColors.scrollbarDark), radius: const Radius.circular(AdminRadius.full), thickness: WidgetStateProperty.all(6)),
      switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AdminColors.primary : AdminColors.textDarkMuted), trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AdminColors.primary.withValues(alpha: 0.3) : AdminColors.borderDark)),
      sliderTheme: SliderThemeData(activeTrackColor: AdminColors.primary, inactiveTrackColor: AdminColors.bgDarkSurface, thumbColor: AdminColors.primary),
      dialogTheme: DialogThemeData(backgroundColor: AdminColors.bgDarkCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl))),
      tabBarTheme: const TabBarThemeData(labelColor: AdminColors.primary, unselectedLabelColor: AdminColors.textDarkMuted, indicatorColor: AdminColors.primary),
      popupMenuTheme: PopupMenuThemeData(color: AdminColors.bgDarkCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg))),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: AdminColors.bgDarkCard, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(AdminRadius.xxl), topRight: Radius.circular(AdminRadius.xxl)))),
      tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: AdminColors.bgDarkSurface, borderRadius: BorderRadius.circular(AdminRadius.sm)), textStyle: const TextStyle(color: AdminColors.textDarkPrimary)),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AdminColors.bgLight,
      colorScheme: const ColorScheme.light(primary: AdminColors.primary, secondary: AdminColors.secondary, surface: AdminColors.bgLightCard, error: AdminColors.danger),
      fontFamily: AdminTypography.fontFamily,
      appBarTheme: AppBarTheme(backgroundColor: AdminColors.bgLightCard, elevation: 0, centerTitle: false, titleTextStyle: AdminTypography.h4(false), iconTheme: const IconThemeData(color: AdminColors.textLightPrimary)),
      cardTheme: CardThemeData(color: AdminColors.bgLightCard, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xl))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AdminColors.bgLightInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide(color: AdminColors.borderLight)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: const BorderSide(color: AdminColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), hintStyle: const TextStyle(color: AdminColors.textLightMuted), labelStyle: const TextStyle(color: AdminColors.textLightSecondary)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)), textStyle: AdminTypography.buttonText)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: AdminColors.primary, side: const BorderSide(color: AdminColors.primary), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)))),
      chipTheme: ChipThemeData(backgroundColor: AdminColors.bgLightSurface, selectedColor: AdminColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.md)), labelStyle: const TextStyle(fontSize: 11, color: AdminColors.textLightSecondary), side: BorderSide.none),
      dividerTheme: const DividerThemeData(color: AdminColors.dividerLight, thickness: 1, space: 1),
      scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStateProperty.all(AdminColors.scrollbarLight), radius: const Radius.circular(AdminRadius.full), thickness: WidgetStateProperty.all(6)),
      switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AdminColors.primary : AdminColors.textLightMuted), trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AdminColors.primary.withValues(alpha: 0.3) : AdminColors.borderLight)),
      sliderTheme: SliderThemeData(activeTrackColor: AdminColors.primary, inactiveTrackColor: AdminColors.bgLightSurface, thumbColor: AdminColors.primary),
      dialogTheme: DialogThemeData(backgroundColor: AdminColors.bgLightCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl))),
      tabBarTheme: const TabBarThemeData(labelColor: AdminColors.primary, unselectedLabelColor: AdminColors.textLightMuted, indicatorColor: AdminColors.primary),
      popupMenuTheme: PopupMenuThemeData(color: AdminColors.bgLightCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg))),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: AdminColors.bgLightCard, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(AdminRadius.xxl), topRight: Radius.circular(AdminRadius.xxl)))),
      tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: AdminColors.bgLightSurface, borderRadius: BorderRadius.circular(AdminRadius.sm)), textStyle: const TextStyle(color: AdminColors.textLightPrimary)),
    );
  }
}