import 'package:flutter/material.dart';
import 'package:tayyebgo_admin/features/ai/ai_copilot_sheet.dart';

/// Thin entry point used by the TopBar / Command Bar to open the AI Copilot.
/// The full UI lives in [AiCopilotSheet].
class AdminHelper {
  static Future<void> show(BuildContext context) {
    return AiCopilotSheet.show(context);
  }
}
