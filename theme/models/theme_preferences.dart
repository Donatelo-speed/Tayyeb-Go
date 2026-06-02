// theme/models/theme_preferences.dart
import 'package:flutter/material.dart';
import 'dart:convert';

/// A model that represents a restaurant's optional UI customisation.  
/// All values are optional – the UI should fall back to the app defaults
/// when a field is `null`.
class ThemePreferences {
  /// Primary brand colour. When set it overrides the global colour palette.
  /// Represented as a HEX string `#RRGGBB` or `#AARRGGBB`. 
  final String? primaryColorHex;

  /// Secondary accent colour (used for buttons, progress bars etc.).
  final String? accentColorHex;

  /// Optional text colour used in the header or overlay widgets.
  final String? headerTextColorHex;

  /// URL or asset path to the banner image.
  final String? bannerUrl;

  /// Optional layout preset name like "minimal", "colorful", "compact".
  final String? layoutPreset;

  ThemePreferences({
    this.primaryColorHex,
    this.accentColorHex,
    this.headerTextColorHex,
    this.bannerUrl,
    this.layoutPreset,
  });

  /// Convenience getters that convert hex string into a `Color` object.  
  /// Empty or invalid strings return `null` and the consuming widget
  /// can fall back to defaults.
  Color? get primaryColor => _colorFromHex(primaryColorHex);
  Color? get accentColor => _colorFromHex(accentColorHex);
  Color? get headerTextColor => _colorFromHex(headerTextColorHex);

  static Color? _colorFromHex(String? hexStr) {
    if (hexStr == null) return null;
    final cleaned = hexStr.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return null;
  }

  /// Creates a new instance from a JSON map.
  factory ThemePreferences.fromJson(Map<String, dynamic> json) {
    return ThemePreferences(
      primaryColorHex: json['primaryColor'] as String?,
      accentColorHex: json['accentColor'] as String?,
      headerTextColorHex: json['headerTextColor'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      layoutPreset: json['layoutPreset'] as String?,
    );
  }

  /// Converts the instance back to a JSON map.
  Map<String, dynamic> toJson() => {
        'primaryColor': primaryColorHex,
        'accentColor': accentColorHex,
        'headerTextColor': headerTextColorHex,
        'bannerUrl': bannerUrl,
        'layoutPreset': layoutPreset,
      };

  /// Helper for decoding a full JSON string.
  factory ThemePreferences.fromJsonString(String jsonString) {
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return ThemePreferences.fromJson(decoded);
  }

  /// Encodes the instance to a JSON string.
  String toJsonString() => json.encode(toJson());
}