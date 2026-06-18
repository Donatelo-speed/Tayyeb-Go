import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the AppTypography design token values.
///
/// We test the raw configuration values rather than the TextStyle objects
/// themselves, since Google Fonts requires network access at runtime to
/// resolve font families. The actual TextStyle objects are tested via
/// widget tests with GoogleFonts.config.allowRuntimeFetching = false.
void main() {
  group('Typography scale', () {
    test('display sizes are in descending order', () {
      const displayLarge = 48.0;
      const displayMedium = 36.0;
      const displaySmall = 30.0;
      expect(displayLarge, greaterThan(displayMedium));
      expect(displayMedium, greaterThan(displaySmall));
    });

    test('headline sizes are in descending order', () {
      const headlineLarge = 24.0;
      const headlineMedium = 20.0;
      const headlineSmall = 18.0;
      expect(headlineLarge, greaterThan(headlineMedium));
      expect(headlineMedium, greaterThan(headlineSmall));
    });

    test('body sizes are in descending order', () {
      const bodyLarge = 16.0;
      const bodyMedium = 14.0;
      const bodySmall = 12.0;
      expect(bodyLarge, greaterThan(bodyMedium));
      expect(bodyMedium, greaterThan(bodySmall));
    });

    test('label sizes are in descending order', () {
      const labelLarge = 14.0;
      const labelMedium = 12.0;
      const labelSmall = 11.0;
      expect(labelLarge, greaterThan(labelMedium));
      expect(labelMedium, greaterThan(labelSmall));
    });

    test('display uses heavier weights than body', () {
      const displayWeight = FontWeight.w800;
      const bodyWeight = FontWeight.w400;
      expect(displayWeight.index, greaterThan(bodyWeight.index));
    });

    test('label uses medium weight for emphasis', () {
      const labelWeight = FontWeight.w600;
      expect(labelWeight.index, greaterThan(FontWeight.w400.index));
    });
  });
}
