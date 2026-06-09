import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

const _kThemePref = 'tayyebgo_theme_mode';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark ||
      (_mode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  ThemeProvider() {
    _loadSaved();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_mode == ThemeMode.system) notifyListeners();
    };
  }

  Future<void> _loadSaved() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(_kThemePref);
    if (saved != null) {
      _mode = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  void setMode(ThemeMode mode) {
    if (_mode != mode) {
      _mode = mode;
      _prefs?.setString(_kThemePref, mode.name);
      _updateSystemUI();
      notifyListeners();
    }
  }

  void toggle() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    setMode(next);
  }

  void _updateSystemUI() {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: brightness,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? AppColors.surface : LightAppColors.background,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }
}

/// Context extension for convenient dark/light color access
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Primary
  Color get primaryColor => isDark ? AppColors.primary : LightAppColors.primary;
  Color get primarySoftColor => isDark ? AppColors.primarySoft : LightAppColors.primarySoft;
  Color get primaryAltColor => isDark ? AppColors.primaryAlt : LightAppColors.primaryAlt;

  // Background
  Color get backgroundColor => isDark ? AppColors.background : LightAppColors.background;
  Color get surfaceColor => isDark ? AppColors.surface : LightAppColors.surface;
  Color get surfaceAltColor => isDark ? AppColors.surfaceAlt : LightAppColors.surfaceAlt;
  Color get surfaceHoverColor => isDark ? AppColors.surfaceHover : LightAppColors.surfaceHover;
  Color get cardBgColor => isDark ? AppColors.cardBackground : LightAppColors.cardBackground;

  // Text
  Color get textPrimaryColor => isDark ? AppColors.textPrimary : LightAppColors.textPrimary;
  Color get textSecondaryColor => isDark ? AppColors.textSecondary : LightAppColors.textSecondary;
  Color get textTertiaryColor => isDark ? AppColors.textTertiary : LightAppColors.textTertiary;
  Color get textMutedColor => isDark ? AppColors.textMuted : LightAppColors.textMuted;
  Color get textInverseColor => isDark ? AppColors.textInverse : LightAppColors.textInverse;

  // Border
  Color get borderColor => isDark ? AppColors.border : LightAppColors.border;
  Color get borderStrongColor => isDark ? AppColors.borderStrong : LightAppColors.borderStrong;
  Color get dividerColor => isDark ? AppColors.divider : LightAppColors.divider;

  // Status
  Color get errorColor => isDark ? AppColors.error : LightAppColors.error;
  Color get errorSoftColor => isDark ? AppColors.errorSoft : LightAppColors.errorSoft;
  Color get successColor => isDark ? AppColors.success : LightAppColors.success;
  Color get successSoftColor => isDark ? AppColors.successSoft : LightAppColors.successSoft;
  Color get warningColor => isDark ? AppColors.warning : LightAppColors.warning;
  Color get warningSoftColor => isDark ? AppColors.warningSoft : LightAppColors.warningSoft;

  // Accent
  Color get accentColor => isDark ? AppColors.accent : LightAppColors.accent;
  Color get premiumColor => isDark ? AppColors.premium : LightAppColors.premium;
  Color get premiumSoftColor => isDark ? AppColors.premiumSoft : LightAppColors.premiumSoft;
  Color get purpleColor => isDark ? AppColors.purple : LightAppColors.purple;
  Color get cyanColor => isDark ? AppColors.cyan : LightAppColors.cyan;
  Color get emeraldColor => isDark ? AppColors.emerald : LightAppColors.emerald;
  Color get amberColor => isDark ? AppColors.amber : LightAppColors.amber;

  // Shadow
  Color get shadowColor => isDark ? AppColors.shadow : LightAppColors.shadow;

  // Card
  Color get cardBackgroundColor => isDark ? AppColors.cardBackground : LightAppColors.cardBackground;

  // Sidebar
  Color get sidebarBgColor => isDark ? AppColors.sidebarBg : LightAppColors.sidebarBg;
  Color get sidebarTextColor => isDark ? AppColors.sidebarText : LightAppColors.sidebarText;
  Color get sidebarMutedColor => isDark ? AppColors.sidebarMuted : LightAppColors.sidebarMuted;
  Color get sidebarActiveColor => isDark ? AppColors.sidebarActive : LightAppColors.sidebarActive;
  Color get sidebarActiveBgColor => isDark ? AppColors.sidebarActiveBg : LightAppColors.sidebarActiveBg;
  Color get sidebarBorderColor => isDark ? AppColors.sidebarBorder : LightAppColors.sidebarBorder;
}
