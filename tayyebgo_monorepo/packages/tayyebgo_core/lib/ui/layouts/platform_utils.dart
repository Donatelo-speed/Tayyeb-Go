import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Platform detection and adaptation utilities.
///
/// Centralizes platform checks so all apps handle mobile/web/desktop consistently.
abstract class PlatformUtils {
  /// True when running on Android or iOS (not web).
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// True when running on Windows, macOS, or Linux (not web).
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// True when running in a web browser.
  static bool get isWeb => kIsWeb;

  /// True when running on macOS (desktop or web on macOS).
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// True when running on iOS or macOS (Apple ecosystem).
  static bool get isApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  /// Platform-adaptive icon size.
  static double iconSize(BuildContext context) {
    final platform = Theme.of(context).platform;
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 24.0;
      case TargetPlatform.windows:
        return 20.0;
      default:
        return 24.0;
    }
  }

  /// Platform-adaptive border radius for cards.
  static double get cardRadius {
    if (isApple) return 16.0;
    return 12.0;
  }

  /// Platform-adaptive border radius for buttons.
  static double get buttonRadius {
    if (isApple) return 12.0;
    return 8.0;
  }

  /// Platform-adaptive haptic feedback pattern.
  static void hapticLight() {
    // Haptic feedback is handled per-platform via services
  }

  /// Returns the target platform for the current context.
  static TargetPlatform platform(BuildContext context) =>
      Theme.of(context).platform;
}
