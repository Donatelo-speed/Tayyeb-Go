import 'package:flutter/material.dart';

/// Accessibility helpers for TayyebGo — provides semantic labels, screen reader
/// support, and ensures WCAG AA contrast compliance.
class AccessibilityHelper {
  /// Wraps a widget with a Semantic label for screen readers.
  static Widget semantically({
    required BuildContext context,
    required String label,
    required Widget child,
    bool button = false,
    bool enabled = true,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      button: button,
      enabled: enabled,
      onLongPress: onLongPress,
      child: child,
    );
  }

  /// Wraps an image with a semantic description.
  static Widget image({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      child: child,
    );
  }

  /// Creates a semantic header for sections.
  static Widget header({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }

  /// Wraps a card/list tile with semantic role and label.
  static Widget card({
    required BuildContext context,
    required String label,
    required Widget child,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return Semantics(
      label: label,
      button: onTap != null,
      selected: selected,
      onTap: onTap,
      child: child,
    );
  }

  /// Ensures text meets WCAG AA contrast ratio (4.5:1 for normal text, 3:1 for large text).
  /// Returns the color if it meets contrast, otherwise adjusts it.
  static Color ensureContrast({
    required Color foreground,
    required Color background,
    bool largeText = false,
  }) {
    final ratio = _contrastRatio(foreground, background);
    final minRatio = largeText ? 3.0 : 4.5;
    if (ratio >= minRatio) return foreground;
    // Darken or lighten to meet contrast
    return _adjustForContrast(foreground, background, minRatio);
  }

  static double _contrastRatio(Color c1, Color c2) {
    final l1 = _relativeLuminance(c1);
    final l2 = _relativeLuminance(c2);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _relativeLuminance(Color c) {
    final r = c.r / 255.0;
    final g = c.g / 255.0;
    final b = c.b / 255.0;
    final rs = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055);
    final gs = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055);
    final bs = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055);
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
  }

  static Color _adjustForContrast(Color fg, Color bg, double targetRatio) {
    // Try darkening first
    for (double factor = 0.9; factor > 0.1; factor -= 0.1) {
      final adjusted = Color.lerp(fg, Colors.black, 1 - factor)!;
      if (_contrastRatio(adjusted, bg) >= targetRatio) return adjusted;
    }
    // Try lightening
    for (double factor = 0.9; factor > 0.1; factor -= 0.1) {
      final adjusted = Color.lerp(fg, Colors.white, 1 - factor)!;
      if (_contrastRatio(adjusted, bg) >= targetRatio) return adjusted;
    }
    return fg;
  }
}
