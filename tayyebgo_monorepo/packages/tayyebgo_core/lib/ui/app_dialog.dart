import 'dart:ui';
import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';
import '../presentation/theme/app_shadow.dart';
import '../presentation/theme/app_motion.dart';
import 'app_button.dart';

/// TGDialog — Blur background + scale-in dialog
class TGDialog extends StatefulWidget {
  final String? title;
  final Widget content;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;

  const TGDialog({
    super.key,
    this.title,
    required this.content,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.isDestructive = false,
  });

  static Future<void> show({
    required BuildContext context,
    String? title,
    required Widget content,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dialog',
      barrierColor: AppColors.scrim,
      transitionDuration: AppMotion.medium,
      pageBuilder: (context, animation, secondaryAnimation) {
        return TGDialog(
          title: title,
          content: content,
          primaryActionLabel: primaryActionLabel,
          onPrimaryAction: onPrimaryAction,
          secondaryActionLabel: secondaryActionLabel,
          onSecondaryAction: onSecondaryAction,
          isDestructive: isDestructive,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<TGDialog> createState() => _TGDialogState();
}

class _TGDialogState extends State<TGDialog> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : AppColors.surface,
          borderRadius: AppRadius.brDialog,
          boxShadow: AppShadow.elevation4(isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            widget.content,
            const SizedBox(height: 24),
            Row(
              children: [
                if (widget.secondaryActionLabel != null) ...[
                  Expanded(
                    child: TGB.ghost(
                      label: widget.secondaryActionLabel!,
                      onPressed: widget.onSecondaryAction ??
                          () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (widget.primaryActionLabel != null)
                  Expanded(
                    child: widget.isDestructive
                        ? TGB.destructive(
                            label: widget.primaryActionLabel!,
                            onPressed: widget.onPrimaryAction ??
                                () => Navigator.of(context).pop(),
                          )
                        : TGB.primary(
                            label: widget.primaryActionLabel!,
                            onPressed: widget.onPrimaryAction ??
                                () => Navigator.of(context).pop(),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
