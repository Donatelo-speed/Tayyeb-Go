import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isCompact;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isCompact = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final height = isCompact ? 40.0 : 50.0;
    final radius = BorderRadius.circular(12);
    final textStyle = TextStyle(
      fontSize: isCompact ? 13 : 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return _buildElevated(
          height: height,
          radius: radius,
          textStyle: textStyle,
          disabled: disabled,
          bgColor: AppColors.primary,
          fgColor: Colors.white,
          shadowColor: AppColors.primary,
        );
      case AppButtonVariant.secondary:
        return _buildElevated(
          height: height,
          radius: radius,
          textStyle: textStyle,
          disabled: disabled,
          bgColor: AppColors.primarySoft,
          fgColor: AppColors.primary,
          shadowColor: Colors.transparent,
        );
      case AppButtonVariant.outline:
        return _buildOutlined(
          height: height,
          radius: radius,
          textStyle: textStyle,
          disabled: disabled,
        );
      case AppButtonVariant.text:
        return _buildText(textStyle: textStyle, disabled: disabled);
      case AppButtonVariant.danger:
        return _buildElevated(
          height: height,
          radius: radius,
          textStyle: textStyle,
          disabled: disabled,
          bgColor: AppColors.error,
          fgColor: Colors.white,
          shadowColor: AppColors.error,
        );
    }
  }

  Widget _buildElevated({
    required double height,
    required BorderRadius radius,
    required TextStyle textStyle,
    required bool disabled,
    required Color bgColor,
    required Color fgColor,
    required Color shadowColor,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? bgColor.withValues(alpha: 0.5) : bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textStyle,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }

  Widget _buildOutlined({
    required double height,
    required BorderRadius radius,
    required TextStyle textStyle,
    required bool disabled,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(
            color: disabled
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.3),
          ),
          textStyle: textStyle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildText({required TextStyle textStyle, required bool disabled}) {
    return TextButton(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: textStyle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
