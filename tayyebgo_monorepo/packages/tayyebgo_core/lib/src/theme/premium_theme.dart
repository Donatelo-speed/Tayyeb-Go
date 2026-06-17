import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium design system for TayyebGo Flutter apps.
///
/// CSS-inspired design tokens executed in Dart/Flutter with Material 3.
/// Primary: #F97316 (orange), Secondary: #8B5CF6 (purple), Accent: #22C55E (green)
class PremiumTheme {
  PremiumTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // COLOR PALETTE
  // ══════════════════════════════════════════════════════════════════════════

  static const Color primary = Color(0xFFF97316);
  static const Color primaryHover = Color(0xFFFB923C);
  static const Color primarySoft = Color(0x26F97316);
  static const Color primaryLight = Color(0x33F97316);

  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryHover = Color(0xFFA78BFA);
  static const Color secondarySoft = Color(0x268B5CF6);
  static const Color secondaryLight = Color(0x338B5CF6);

  static const Color accent = Color(0xFF22C55E);
  static const Color accentHover = Color(0xFF4ADE80);
  static const Color accentSoft = Color(0x2622C55E);
  static const Color accentLight = Color(0x3322C55E);

  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0x26EF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0x26F59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0x263B82F6);

  // ── Dark surfaces ──
  static const Color darkBackground = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF18181B);
  static const Color darkSurfaceAlt = Color(0xFF27272A);
  static const Color darkSurfaceElevated = Color(0xFF1E1E22);
  static const Color darkBorder = Color(0xFF3F3F46);
  static const Color darkDivider = Color(0xFF27272A);

  // ── Light surfaces ──
  static const Color lightBackground = Color(0xFFFAFAF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF4F4F5);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightDivider = Color(0xFFF4F4F5);

  // ── Text ──
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextMuted = Color(0xFF71717A);

  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFFA1A1AA);

  // ── Glass / Frosted ──
  static const Color darkGlass = Color(0xB318181B);
  static const Color darkGlassBorder = Color(0x1FFFFFFF);
  static const Color lightGlass = Color(0xD9FFFFFF);
  static const Color lightGlassBorder = Color(0x80FFFFFF);

  // ── Glow ──
  static const Color glowPrimary = Color(0x40F97316);
  static const Color glowSecondary = Color(0x408B5CF6);
  static const Color glowAccent = Color(0x4022C55E);

  // ══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY SCALE
  // ══════════════════════════════════════════════════════════════════════════

  static TextStyle get displayLarge => GoogleFonts.hankenGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.5,
      );

  static TextStyle get displayMedium => GoogleFonts.hankenGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1,
      );

  static TextStyle get displaySmall => GoogleFonts.hankenGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.75,
      );

  static TextStyle get headingLarge => GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle get headingSmall => GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.8,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // SPACING SCALE (CSS-style 4px base)
  // ══════════════════════════════════════════════════════════════════════════

  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space12 = 48;
  static const double space16 = 64;

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS SCALE
  // ══════════════════════════════════════════════════════════════════════════

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radius3xl = 32;
  static const double radiusFull = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius br2xl = BorderRadius.all(Radius.circular(radius2xl));
  static const BorderRadius br3xl = BorderRadius.all(Radius.circular(radius3xl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(radiusFull));

  static const BorderRadius brCard = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brButton = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brInput = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brChip = BorderRadius.all(Radius.circular(radiusFull));
  static const BorderRadius brAvatar = BorderRadius.all(Radius.circular(radiusFull));
  static const BorderRadius brDialog = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius brBottomSheet = BorderRadius.vertical(
    top: Radius.circular(radiusXl),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // SHADOW SYSTEM
  // ══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSm => const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 32,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowXl => const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 56,
          offset: Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get glowShadowPrimary => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 24,
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> get glowShadowSecondary => [
        BoxShadow(
          color: secondary.withValues(alpha: 0.3),
          blurRadius: 24,
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> get glowShadowAccent => [
        BoxShadow(
          color: accent.withValues(alpha: 0.3),
          blurRadius: 24,
          spreadRadius: -6,
        ),
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // ANIMATION CURVES
  // ══════════════════════════════════════════════════════════════════════════

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve springSoft = Curves.easeOutBack;
  static const Curve bounce = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.easeInCubic;

  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationLazy = Duration(milliseconds: 700);

  // ══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coolGradient = LinearGradient(
    colors: [accent, info],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondarySoft,
      onSecondaryContainer: secondary,
      tertiary: accent,
      onTertiary: Colors.white,
      tertiaryContainer: accentSoft,
      onTertiaryContainer: accent,
      error: error,
      onError: Colors.white,
      errorContainer: errorSoft,
      onErrorContainer: error,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainer: darkSurfaceAlt,
      surfaceContainerHighest: darkSurfaceElevated,
      outline: darkBorder,
      outlineVariant: darkDivider,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      textTheme: _darkTextTheme(),
      appBarTheme: _darkAppBarTheme(),
      inputDecorationTheme: _darkInputDecoration(),
      elevatedButtonTheme: _darkElevatedButton(),
      outlinedButtonTheme: _darkOutlinedButton(),
      textButtonTheme: _darkTextButton(),
      navigationBarTheme: _darkNavigationBarTheme(),
      chipTheme: _darkChipTheme(),
      cardTheme: _darkCardTheme(),
      bottomSheetTheme: _darkBottomSheetTheme(),
      dialogTheme: _darkDialogTheme(),
      snackBarTheme: _darkSnackBarTheme(),
      tabBarTheme: _darkTabBarTheme(),
      floatingActionButtonTheme: _darkFabTheme(),
      listTileTheme: _darkListTileTheme(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondarySoft,
      onSecondaryContainer: secondary,
      tertiary: accent,
      onTertiary: Colors.white,
      tertiaryContainer: accentSoft,
      onTertiaryContainer: accent,
      error: error,
      onError: Colors.white,
      errorContainer: errorSoft,
      onErrorContainer: error,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainer: lightSurfaceAlt,
      surfaceContainerHighest: lightSurfaceElevated,
      outline: lightBorder,
      outlineVariant: lightDivider,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      textTheme: _lightTextTheme(),
      appBarTheme: _lightAppBarTheme(),
      inputDecorationTheme: _lightInputDecoration(),
      elevatedButtonTheme: _lightElevatedButton(),
      outlinedButtonTheme: _lightOutlinedButton(),
      textButtonTheme: _lightTextButton(),
      navigationBarTheme: _lightNavigationBarTheme(),
      chipTheme: _lightChipTheme(),
      cardTheme: _lightCardTheme(),
      bottomSheetTheme: _lightBottomSheetTheme(),
      dialogTheme: _lightDialogTheme(),
      snackBarTheme: _lightSnackBarTheme(),
      tabBarTheme: _lightTabBarTheme(),
      floatingActionButtonTheme: _lightFabTheme(),
      listTileTheme: _lightListTileTheme(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  static TextTheme _darkTextTheme() => TextTheme(
        displayLarge: displayLarge.copyWith(color: darkTextPrimary),
        displayMedium: displayMedium.copyWith(color: darkTextPrimary),
        displaySmall: displaySmall.copyWith(color: darkTextPrimary),
        headlineLarge: headingLarge.copyWith(color: darkTextPrimary),
        headlineMedium: headingMedium.copyWith(color: darkTextPrimary),
        headlineSmall: headingSmall.copyWith(color: darkTextPrimary),
        titleLarge: GoogleFonts.hankenGrotesk(
          fontSize: 18, fontWeight: FontWeight.w700, color: darkTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: secondary,
        ),
        bodyLarge: bodyLarge.copyWith(color: darkTextPrimary),
        bodyMedium: bodyMedium.copyWith(color: darkTextPrimary),
        bodySmall: bodySmall.copyWith(color: darkTextSecondary),
        labelLarge: labelLarge.copyWith(color: darkTextPrimary),
        labelMedium: labelMedium.copyWith(color: darkTextSecondary),
        labelSmall: labelSmall.copyWith(color: darkTextMuted),
      );

  static AppBarTheme _darkAppBarTheme() => AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      );

  static InputDecorationTheme _darkInputDecoration() => InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: darkTextMuted),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: darkTextMuted),
      );

  static ElevatedButtonThemeData _darkElevatedButton() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  static OutlinedButtonThemeData _darkOutlinedButton() => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  static TextButtonThemeData _darkTextButton() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  static NavigationBarThemeData _darkNavigationBarTheme() => NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: selected ? primary : darkTextMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : darkTextMuted, size: 22);
        }),
      );

  static ChipThemeData _darkChipTheme() => ChipThemeData(
        backgroundColor: darkSurfaceAlt,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: darkTextPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: brChip),
        side: const BorderSide(color: darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );

  static CardThemeData _darkCardTheme() => CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: brCard,
          side: BorderSide(color: darkBorder),
        ),
      );

  static BottomSheetThemeData _darkBottomSheetTheme() => BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      );

  static DialogThemeData _darkDialogTheme() => DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: brDialog),
      );

  static SnackBarThemeData _darkSnackBarTheme() => SnackBarThemeData(
        backgroundColor: darkTextPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: darkBackground,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(borderRadius: brButton),
        behavior: SnackBarBehavior.floating,
      );

  static TabBarThemeData _darkTabBarTheme() => TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: darkTextMuted,
        indicatorColor: primary,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      );

  static FloatingActionButtonThemeData _darkFabTheme() => FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: brButton),
      );

  static ListTileThemeData _darkListTileTheme() => ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: brCard),
        iconColor: darkTextMuted,
        textColor: darkTextPrimary,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  static TextTheme _lightTextTheme() => TextTheme(
        displayLarge: displayLarge.copyWith(color: lightTextPrimary),
        displayMedium: displayMedium.copyWith(color: lightTextPrimary),
        displaySmall: displaySmall.copyWith(color: lightTextPrimary),
        headlineLarge: headingLarge.copyWith(color: lightTextPrimary),
        headlineMedium: headingMedium.copyWith(color: lightTextPrimary),
        headlineSmall: headingSmall.copyWith(color: lightTextPrimary),
        titleLarge: GoogleFonts.hankenGrotesk(
          fontSize: 18, fontWeight: FontWeight.w700, color: lightTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: secondary,
        ),
        bodyLarge: bodyLarge.copyWith(color: lightTextPrimary),
        bodyMedium: bodyMedium.copyWith(color: lightTextPrimary),
        bodySmall: bodySmall.copyWith(color: lightTextSecondary),
        labelLarge: labelLarge.copyWith(color: lightTextPrimary),
        labelMedium: labelMedium.copyWith(color: lightTextSecondary),
        labelSmall: labelSmall.copyWith(color: lightTextMuted),
      );

  static AppBarTheme _lightAppBarTheme() => AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      );

  static InputDecorationTheme _lightInputDecoration() => InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: lightBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: lightBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: brInput,
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: lightTextMuted),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: lightTextMuted),
      );

  static ElevatedButtonThemeData _lightElevatedButton() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  static OutlinedButtonThemeData _lightOutlinedButton() => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  static TextButtonThemeData _lightTextButton() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: brButton),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  static NavigationBarThemeData _lightNavigationBarTheme() => NavigationBarThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: selected ? primary : lightTextMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : lightTextMuted, size: 22);
        }),
      );

  static ChipThemeData _lightChipTheme() => ChipThemeData(
        backgroundColor: lightSurfaceAlt,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: lightTextPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: brChip),
        side: const BorderSide(color: lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );

  static CardThemeData _lightCardTheme() => CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: brCard,
          side: BorderSide(color: lightBorder),
        ),
      );

  static BottomSheetThemeData _lightBottomSheetTheme() => BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      );

  static DialogThemeData _lightDialogTheme() => DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: brDialog),
      );

  static SnackBarThemeData _lightSnackBarTheme() => SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: lightSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(borderRadius: brButton),
        behavior: SnackBarBehavior.floating,
      );

  static TabBarThemeData _lightTabBarTheme() => TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: lightTextMuted,
        indicatorColor: primary,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      );

  static FloatingActionButtonThemeData _lightFabTheme() => FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: brButton),
      );

  static ListTileThemeData _lightListTileTheme() => ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: brCard),
        iconColor: lightTextMuted,
        textColor: lightTextPrimary,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color surfaceAltColor(BuildContext context) =>
      isDark(context) ? darkSurfaceAlt : lightSurfaceAlt;

  static Color textPrimaryColor(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;
}
