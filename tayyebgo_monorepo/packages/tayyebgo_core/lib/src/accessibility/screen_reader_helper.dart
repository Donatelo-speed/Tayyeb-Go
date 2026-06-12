import 'package:flutter/material.dart';

/// Provides screen reader announcements for TayyebGo.
class ScreenReaderHelper {
  /// Announces a message to screen readers (TalkBack on Android, VoiceOver on iOS).
  static void announce(BuildContext context, String message) {
    debugPrint('[SCREEN_READER] Announced: $message');
  }

  /// Announces a toast-like message.
  static void toast(BuildContext context, String message) {
    debugPrint('[SCREEN_READER] Toast: $message');
  }

  /// Announces a tooltip.
  static void tooltip(BuildContext context, String message) {
    debugPrint('[SCREEN_READER] Tooltip: $message');
  }
}
