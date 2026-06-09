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

  Color _bg(BuildContext context) {
    switch (kind) {
      case AppToastKind.success: return context.successColor;
      case AppToastKind.error: return context.errorColor;
      case AppToastKind.warning: return context.warningColor;
      case AppToastKind.info: return context.primaryColor;
      case AppToastKind.neutral: return context.surfaceAltColor;
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
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
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
                    style: AppTypography.label.copyWith(color: Colors.white)),
              ),
          ],
        ),
        backgroundColor: toast._bg(this),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
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
  bool? result;
  await TGDialog.show(
    context: context,
    title: title,
    content: Text(message, style: AppTypography.body.copyWith(color: context.textSecondaryColor)),
    primaryActionLabel: confirmLabel,
    onPrimaryAction: () { result = true; Navigator.of(context).pop(); },
    secondaryActionLabel: cancelLabel,
    onSecondaryAction: () { result = false; Navigator.of(context).pop(); },
    isDestructive: destructive,
  );
  return result == true;
}
