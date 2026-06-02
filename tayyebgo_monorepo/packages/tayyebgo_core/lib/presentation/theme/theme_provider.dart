import 'package:flutter/material.dart';
import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  void toggle() {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

extension ThemeColors on BuildContext {
  Color get primaryColor => isDark ? DarkAppColors.primary : AppColors.primary;
  Color get primarySoftColor => isDark ? DarkAppColors.primarySoft : AppColors.primarySoft;
  Color get primaryAltColor => isDark ? DarkAppColors.primaryAlt : AppColors.primaryAlt;
  Color get backgroundColor =>
      isDark ? DarkAppColors.background : AppColors.background;
  Color get surfaceColor =>
      isDark ? DarkAppColors.surface : AppColors.surface;
  Color get surfaceAltColor =>
      isDark ? DarkAppColors.surfaceAlt : AppColors.surfaceAlt;
  Color get surfaceHoverColor =>
      isDark ? DarkAppColors.surfaceHover : AppColors.surfaceHover;
  Color get textPrimaryColor =>
      isDark ? DarkAppColors.textPrimary : AppColors.textPrimary;
  Color get textSecondaryColor =>
      isDark ? DarkAppColors.textSecondary : AppColors.textSecondary;
  Color get textTertiaryColor =>
      isDark ? DarkAppColors.textTertiary : AppColors.textTertiary;
  Color get textMutedColor =>
      isDark ? DarkAppColors.textMuted : AppColors.textMuted;
  Color get textInverseColor =>
      isDark ? DarkAppColors.textInverse : AppColors.textInverse;
  Color get borderColor => isDark ? DarkAppColors.border : AppColors.border;
  Color get borderStrongColor => isDark ? DarkAppColors.borderStrong : AppColors.borderStrong;
  Color get dividerColor => isDark ? DarkAppColors.divider : AppColors.divider;
  Color get errorColor => isDark ? DarkAppColors.error : AppColors.error;
  Color get errorSoftColor => isDark ? DarkAppColors.errorSoft : AppColors.errorSoft;
  Color get successColor =>
      isDark ? DarkAppColors.success : AppColors.success;
  Color get successSoftColor => isDark ? DarkAppColors.successSoft : AppColors.successSoft;
  Color get warningColor =>
      isDark ? DarkAppColors.warning : AppColors.warning;
  Color get warningSoftColor => isDark ? DarkAppColors.warningSoft : AppColors.warningSoft;
  Color get accentColor => isDark ? DarkAppColors.accent : AppColors.accent;
  Color get premiumColor => isDark ? DarkAppColors.premium : AppColors.premium;
  Color get premiumSoftColor => isDark ? DarkAppColors.premiumSoft : AppColors.premiumSoft;
  Color get purpleColor => isDark ? DarkAppColors.purple : AppColors.purple;
  Color get cyanColor => isDark ? DarkAppColors.cyan : AppColors.cyan;
  Color get emeraldColor => isDark ? DarkAppColors.emerald : AppColors.emerald;
  Color get amberColor => isDark ? DarkAppColors.amber : AppColors.amber;
  Color get shadowColor => isDark ? DarkAppColors.shadow : AppColors.shadow;
  Color get cardBackgroundColor => isDark ? DarkAppColors.cardBackground : AppColors.cardBackground;
  Color get sidebarBgColor => isDark ? DarkAppColors.sidebarBg : AppColors.sidebarBg;
  Color get sidebarTextColor => isDark ? DarkAppColors.sidebarText : AppColors.sidebarText;
  Color get sidebarMutedColor => isDark ? DarkAppColors.sidebarMuted : AppColors.sidebarMuted;
  Color get sidebarActiveColor => isDark ? DarkAppColors.sidebarActive : AppColors.sidebarActive;
  Color get sidebarActiveBgColor => isDark ? DarkAppColors.sidebarActiveBg : AppColors.sidebarActiveBg;
  Color get sidebarBorderColor => isDark ? DarkAppColors.sidebarBorder : AppColors.sidebarBorder;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
