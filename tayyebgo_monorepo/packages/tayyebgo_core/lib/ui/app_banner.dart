import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';

/// TGBanner — Alert/notification banner
enum TGBannerVariant { info, success, warning, error }

class TGBanner extends StatelessWidget {
  final String message;
  final TGBannerVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Widget? trailing;

  const TGBanner({
    super.key,
    required this.message,
    this.variant = TGBannerVariant.info,
    this.icon,
    this.onTap,
    this.onDismiss,
    this.trailing,
  });

  const TGBanner.info({super.key, required this.message, this.onTap, this.onDismiss, this.trailing})
      : variant = TGBannerVariant.info,
        icon = null;

  const TGBanner.success({super.key, required this.message, this.onTap, this.onDismiss, this.trailing})
      : variant = TGBannerVariant.success,
        icon = null;

  const TGBanner.warning({super.key, required this.message, this.onTap, this.onDismiss, this.trailing})
      : variant = TGBannerVariant.warning,
        icon = null;

  const TGBanner.error({super.key, required this.message, this.onTap, this.onDismiss, this.trailing})
      : variant = TGBannerVariant.error,
        icon = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: config.borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: config.iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon ?? config.icon, size: 16, color: config.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: config.textColor,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close_rounded, size: 16, color: config.iconColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _BannerConfig _getConfig(bool isDark) {
    switch (variant) {
      case TGBannerVariant.info:
        return _BannerConfig(
          bgColor: isDark ? const Color(0xFF1A2332) : const Color(0xFFEFF6FF),
          borderColor: isDark ? AppColors.border : const Color(0xFFBFDBFE),
          iconBgColor: isDark ? AppColors.primarySoft : const Color(0xFFDBEAFE),
          iconColor: AppColors.primary,
          icon: Icons.info_outline_rounded,
          textColor: isDark ? AppColors.textPrimary : const Color(0xFF1E3A5F),
        );
      case TGBannerVariant.success:
        return _BannerConfig(
          bgColor: isDark ? const Color(0xFF0F2318) : const Color(0xFFECFDF5),
          borderColor: isDark ? AppColors.border : const Color(0xFFA7F3D0),
          iconBgColor: isDark ? AppColors.successSoft : const Color(0xFFD1FAE5),
          iconColor: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          textColor: isDark ? AppColors.textPrimary : const Color(0xFF065F46),
        );
      case TGBannerVariant.warning:
        return _BannerConfig(
          bgColor: isDark ? const Color(0xFF231A0F) : const Color(0xFFFFFBEB),
          borderColor: isDark ? AppColors.border : const Color(0xFFFDE68A),
          iconBgColor: isDark ? AppColors.warningSoft : const Color(0xFFFEF3C7),
          iconColor: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          textColor: isDark ? AppColors.textPrimary : const Color(0xFF92400E),
        );
      case TGBannerVariant.error:
        return _BannerConfig(
          bgColor: isDark ? const Color(0xFF230F0F) : const Color(0xFFFEF2F2),
          borderColor: isDark ? AppColors.border : const Color(0xFFFECACA),
          iconBgColor: isDark ? AppColors.errorSoft : const Color(0xFFFEE2E2),
          iconColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          textColor: isDark ? AppColors.textPrimary : const Color(0xFF991B1B),
        );
    }
  }
}

class _BannerConfig {
  final Color bgColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color iconColor;
  final IconData icon;
  final Color textColor;

  const _BannerConfig({
    required this.bgColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.icon,
    required this.textColor,
  });
}
