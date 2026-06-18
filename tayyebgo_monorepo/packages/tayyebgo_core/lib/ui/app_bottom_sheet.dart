import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';
import '../presentation/theme/app_shadow.dart';

/// TGBottomSheet — Spring physics modal bottom sheet
class TGBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final double initialChildSize;
  final bool isScrollControlled;

  const TGBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.initialChildSize = 0.5,
    this.isScrollControlled = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    double initialChildSize = 0.5,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (context) {
        return TGBottomSheet(
          title: title,
          initialChildSize: initialChildSize,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brBottomSheet,
        boxShadow: AppShadow.elevation4(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation bottom sheet with actions
class TGConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final String? cancelLabel;
  final bool isDestructive;

  const TGConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel,
    this.isDestructive = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    String? cancelLabel,
    bool isDestructive = false,
  }) {
    return TGBottomSheet.show(
      context: context,
      child: TGConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.brButton,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: AppRadius.brButton,
                    child: Center(
                      child: Text(
                        cancelLabel ?? 'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isDestructive
                  ? Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: AppRadius.brButton,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            onConfirm();
                          },
                          borderRadius: AppRadius.brButton,
                          child: Center(
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        ),
                        borderRadius: AppRadius.brButton,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            onConfirm();
                          },
                          borderRadius: AppRadius.brButton,
                          child: Center(
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
