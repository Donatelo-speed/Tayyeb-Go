import 'package:flutter/material.dart';

abstract class AppStatusColors {
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color premium = Color(0xFF7C3AED);
  static const Color premiumSoft = Color(0xFFEDE9FE);

  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkSuccessSoft = Color(0xFF064E3B);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkWarningSoft = Color(0xFF422006);
  static const Color darkDanger = Color(0xFFF87171);
  static const Color darkDangerSoft = Color(0xFF450A0A);
  static const Color darkInfo = Color(0xFF60A5FA);
  static const Color darkInfoSoft = Color(0xFF1E3A8A);
  static const Color darkNeutral = Color(0xFF94A3B8);
  static const Color darkNeutralSoft = Color(0xFF1F2937);
  static const Color darkPremium = Color(0xFFA78BFA);
  static const Color darkPremiumSoft = Color(0xFF2E1065);

  static const IconData iconSuccess = Icons.check_circle_rounded;
  static const IconData iconWarning = Icons.warning_amber_rounded;
  static const IconData iconDanger = Icons.error_rounded;
  static const IconData iconInfo = Icons.info_rounded;
  static const IconData iconPending = Icons.hourglass_empty_rounded;
  static const IconData iconNeutral = Icons.circle_outlined;
}

class StatusVisual {
  final Color color;
  final Color soft;
  final IconData icon;
  const StatusVisual({required this.color, required this.soft, required this.icon});
}

class AppStatusTheme {
  static StatusVisual success(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusVisual(
      color: isDark ? AppStatusColors.darkSuccess : AppStatusColors.success,
      soft: isDark ? AppStatusColors.darkSuccessSoft : AppStatusColors.successSoft,
      icon: AppStatusColors.iconSuccess,
    );
  }

  static StatusVisual warning(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusVisual(
      color: isDark ? AppStatusColors.darkWarning : AppStatusColors.warning,
      soft: isDark ? AppStatusColors.darkWarningSoft : AppStatusColors.warningSoft,
      icon: AppStatusColors.iconWarning,
    );
  }

  static StatusVisual danger(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusVisual(
      color: isDark ? AppStatusColors.darkDanger : AppStatusColors.danger,
      soft: isDark ? AppStatusColors.darkDangerSoft : AppStatusColors.dangerSoft,
      icon: AppStatusColors.iconDanger,
    );
  }

  static StatusVisual info(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusVisual(
      color: isDark ? AppStatusColors.darkInfo : AppStatusColors.info,
      soft: isDark ? AppStatusColors.darkInfoSoft : AppStatusColors.infoSoft,
      icon: AppStatusColors.iconInfo,
    );
  }

  static StatusVisual neutral(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusVisual(
      color: isDark ? AppStatusColors.darkNeutral : AppStatusColors.neutral,
      soft: isDark ? AppStatusColors.darkNeutralSoft : AppStatusColors.neutralSoft,
      icon: AppStatusColors.iconNeutral,
    );
  }

  static StatusVisual premium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusVisual(
      color: isDark ? AppStatusColors.darkPremium : AppStatusColors.premium,
      soft: isDark ? AppStatusColors.darkPremiumSoft : AppStatusColors.premiumSoft,
      icon: Icons.workspace_premium_rounded,
    );
  }

  static StatusVisual pending(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusVisual(
      color: isDark ? AppStatusColors.darkWarning : AppStatusColors.warning,
      soft: isDark ? AppStatusColors.darkWarningSoft : AppStatusColors.warningSoft,
      icon: AppStatusColors.iconPending,
    );
  }
}
