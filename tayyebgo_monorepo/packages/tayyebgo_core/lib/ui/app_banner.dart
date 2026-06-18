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
                borderRadius: AppRadius.brSm,
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
          bgColor: isDark ? AppColors.infoSoft : AppColors.infoSoft,
          borderColor: isDark ? AppColors.border : AppColors.infoSoft,
          iconBgColor: AppColors.infoSoft,
          iconColor: AppColors.primary,
          icon: Icons.info_outline_rounded,
          textColor: isDark ? AppColors.textPrimary : AppColors.textPrimary,
        );
      case TGBannerVariant.success:
        return _BannerConfig(
          bgColor: isDark ? AppColors.successSoft : AppColors.successSoft,
          borderColor: isDark ? AppColors.border : AppColors.successSoft,
          iconBgColor: AppColors.successSoft,
          iconColor: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          textColor: isDark ? AppColors.textPrimary : AppColors.textPrimary,
        );
      case TGBannerVariant.warning:
        return _BannerConfig(
          bgColor: isDark ? AppColors.warningSoft : AppColors.warningSoft,
          borderColor: isDark ? AppColors.border : AppColors.warningSoft,
          iconBgColor: AppColors.warningSoft,
          iconColor: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          textColor: isDark ? AppColors.textPrimary : AppColors.textPrimary,
        );
      case TGBannerVariant.error:
        return _BannerConfig(
          bgColor: isDark ? AppColors.errorSoft : AppColors.errorSoft,
          borderColor: isDark ? AppColors.border : AppColors.errorSoft,
          iconBgColor: AppColors.errorSoft,
          iconColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          textColor: isDark ? AppColors.textPrimary : AppColors.textPrimary,
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
