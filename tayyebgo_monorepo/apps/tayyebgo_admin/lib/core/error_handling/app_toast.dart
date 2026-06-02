import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

enum AppToastKind { success, error, warning, info, neutral }

class AppToast {
  final String message;
  final AppToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;

  const AppToast({
    required this.message,
    this.kind = AppToastKind.neutral,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
  });

  Color _bg(bool isDark) {
    switch (kind) {
      case AppToastKind.success: return isDark ? DarkAppColors.success : AppColors.success;
      case AppToastKind.error: return isDark ? DarkAppColors.error : AppColors.error;
      case AppToastKind.warning: return isDark ? DarkAppColors.warning : AppColors.warning;
      case AppToastKind.info: return isDark ? DarkAppColors.primary : AppColors.primary;
      case AppToastKind.neutral: return isDark ? DarkAppColors.surfaceAlt : const Color(0xFF1F2937);
    }
  }

  IconData get _icon {
    switch (kind) {
      case AppToastKind.success: return Icons.check_circle_rounded;
      case AppToastKind.error: return Icons.error_rounded;
      case AppToastKind.warning: return Icons.warning_amber_rounded;
      case AppToastKind.info: return Icons.info_rounded;
      case AppToastKind.neutral: return Icons.notifications_rounded;
    }
  }
}

extension AppToastExtension on BuildContext {
  void showToast(AppToast toast) {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(this);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(toast._icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                toast.message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            if (toast.actionLabel != null && toast.onAction != null)
              TextButton(
                onPressed: () {
                  toast.onAction!();
                  messenger.hideCurrentSnackBar();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(toast.actionLabel!.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.4)),
              ),
          ],
        ),
        backgroundColor: toast._bg(isDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: toast.duration,
      ),
    );
  }
}

Future<bool> appConfirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color? confirmColor,
  bool destructive = false,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? DarkAppColors.surface : Colors.white,
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel, style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? (destructive ? AppColors.error : AppColors.primary),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
