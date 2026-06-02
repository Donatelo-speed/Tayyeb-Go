import 'package:flutter/material.dart';

enum StorefrontCardStyle { rounded, flat, elevated }
enum StorefrontBannerLayout { fullWidth, splitLeft, splitRight }
enum StorefrontMenuLayout { grid, list, compact }

/// The complete per-vendor theming contract stored in MongoDB and read at
/// runtime to render each restaurant's unique storefront sheet.
class StorefrontTheme {
  final String vendorId;

  // ─── Colors ─────────────────────────────────────────────────────────────────
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color onPrimaryColor;

  // ─── Typography ──────────────────────────────────────────────────────────────
  /// Google Fonts font family name (e.g. "Playfair Display", "Lato", "Cairo").
  final String fontFamily;

  // ─── Banner ──────────────────────────────────────────────────────────────────
  final String? heroBannerUrl;
  final StorefrontBannerLayout bannerLayout;

  /// Marketing tagline shown over the hero banner.
  final String? tagline;
  final Color? taglineColor;

  // ─── Card styling ────────────────────────────────────────────────────────────
  final StorefrontCardStyle cardStyle;
  final double cardBorderRadius;

  // ─── Menu layout ─────────────────────────────────────────────────────────────
  final StorefrontMenuLayout menuLayout;

  /// Whether to show category chips horizontally at the top.
  final bool showCategoryBar;

  // ─── Promotions ──────────────────────────────────────────────────────────────
  /// URL of a promotional banner (e.g. "Free delivery today!").
  final String? promoBannerUrl;
  final String? promoText;

  // ─── Social proof ────────────────────────────────────────────────────────────
  final bool showReviewHighlights;

  const StorefrontTheme({
    required this.vendorId,
    this.primaryColor = const Color(0xFF16A085),
    this.accentColor = const Color(0xFF00B894),
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.onPrimaryColor = const Color(0xFFFFFFFF),
    this.fontFamily = 'Poppins',
    this.heroBannerUrl,
    this.bannerLayout = StorefrontBannerLayout.fullWidth,
    this.tagline,
    this.taglineColor,
    this.cardStyle = StorefrontCardStyle.rounded,
    this.cardBorderRadius = 16.0,
    this.menuLayout = StorefrontMenuLayout.grid,
    this.showCategoryBar = true,
    this.promoBannerUrl,
    this.promoText,
    this.showReviewHighlights = true,
  });

  // ─── System theme ─────────────────────────────────────────────────────────────

  /// Derives a Material ThemeData from the vendor's palette.
  ThemeData toThemeData() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
          surface: surfaceColor,
          onPrimary: onPrimaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: surfaceColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: cardStyle == StorefrontCardStyle.elevated ? 4 : 0,
          shadowColor: primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            side: cardStyle == StorefrontCardStyle.flat
                ? BorderSide(color: primaryColor.withOpacity(0.12), width: 1)
                : BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: onPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardBorderRadius * 0.75),
            ),
          ),
        ),
      );

  // ─── Serialization ────────────────────────────────────────────────────────────

  factory StorefrontTheme.fromJson(Map<String, dynamic> j) {
    Color parseColor(dynamic value, Color fallback) {
      if (value == null) return fallback;
      try {
        final raw = value.toString();
        final hex = raw.startsWith('#') ? raw.substring(1) : raw;
        return Color(int.parse(
            hex.length == 6 ? 'FF$hex' : hex,
            radix: 16));
      } catch (_) {
        return fallback;
      }
    }

    return StorefrontTheme(
      vendorId: j['vendor_id']?.toString() ?? '',
      primaryColor:
          parseColor(j['primary_color'], const Color(0xFF16A085)),
      accentColor:
          parseColor(j['accent_color'], const Color(0xFF00B894)),
      surfaceColor:
          parseColor(j['surface_color'], const Color(0xFFFFFFFF)),
      onPrimaryColor:
          parseColor(j['on_primary_color'], const Color(0xFFFFFFFF)),
      fontFamily: j['font_family'] ?? 'Poppins',
      heroBannerUrl: j['hero_banner_url'],
      bannerLayout: StorefrontBannerLayout.values.firstWhere(
        (e) => e.name == j['banner_layout'],
        orElse: () => StorefrontBannerLayout.fullWidth,
      ),
      tagline: j['tagline'],
      taglineColor: j['tagline_color'] != null
          ? parseColor(j['tagline_color'], Colors.white)
          : null,
      cardStyle: StorefrontCardStyle.values.firstWhere(
        (e) => e.name == j['card_style'],
        orElse: () => StorefrontCardStyle.rounded,
      ),
      cardBorderRadius:
          double.tryParse(j['card_border_radius']?.toString() ?? '16') ?? 16.0,
      menuLayout: StorefrontMenuLayout.values.firstWhere(
        (e) => e.name == j['menu_layout'],
        orElse: () => StorefrontMenuLayout.grid,
      ),
      showCategoryBar: j['show_category_bar'] ?? true,
      promoBannerUrl: j['promo_banner_url'],
      promoText: j['promo_text'],
      showReviewHighlights: j['show_review_highlights'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'vendor_id': vendorId,
        'primary_color':
            '#${primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'accent_color':
            '#${accentColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'surface_color':
            '#${surfaceColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'on_primary_color':
            '#${onPrimaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'font_family': fontFamily,
        'hero_banner_url': heroBannerUrl,
        'banner_layout': bannerLayout.name,
        'tagline': tagline,
        'tagline_color': taglineColor != null
            ? '#${taglineColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}'
            : null,
        'card_style': cardStyle.name,
        'card_border_radius': cardBorderRadius,
        'menu_layout': menuLayout.name,
        'show_category_bar': showCategoryBar,
        'promo_banner_url': promoBannerUrl,
        'promo_text': promoText,
        'show_review_highlights': showReviewHighlights,
      };

  StorefrontTheme copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? surfaceColor,
    Color? onPrimaryColor,
    String? fontFamily,
    String? heroBannerUrl,
    StorefrontBannerLayout? bannerLayout,
    String? tagline,
    Color? taglineColor,
    StorefrontCardStyle? cardStyle,
    double? cardBorderRadius,
    StorefrontMenuLayout? menuLayout,
    bool? showCategoryBar,
    String? promoBannerUrl,
    String? promoText,
    bool? showReviewHighlights,
  }) =>
      StorefrontTheme(
        vendorId: vendorId,
        primaryColor: primaryColor ?? this.primaryColor,
        accentColor: accentColor ?? this.accentColor,
        surfaceColor: surfaceColor ?? this.surfaceColor,
        onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
        fontFamily: fontFamily ?? this.fontFamily,
        heroBannerUrl: heroBannerUrl ?? this.heroBannerUrl,
        bannerLayout: bannerLayout ?? this.bannerLayout,
        tagline: tagline ?? this.tagline,
        taglineColor: taglineColor ?? this.taglineColor,
        cardStyle: cardStyle ?? this.cardStyle,
        cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
        menuLayout: menuLayout ?? this.menuLayout,
        showCategoryBar: showCategoryBar ?? this.showCategoryBar,
        promoBannerUrl: promoBannerUrl ?? this.promoBannerUrl,
        promoText: promoText ?? this.promoText,
        showReviewHighlights: showReviewHighlights ?? this.showReviewHighlights,
      );

  /// Default fallback theme for vendors who haven't customised theirs.
  static StorefrontTheme defaultFor(String vendorId) =>
      StorefrontTheme(vendorId: vendorId);
}
