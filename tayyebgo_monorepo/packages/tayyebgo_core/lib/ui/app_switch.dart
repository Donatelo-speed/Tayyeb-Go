import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';

/// TGSwitch — Themed toggle switch
class TGSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? label;
  final String? subtitle;

  const TGSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackActive = activeColor ?? AppColors.primary;
    final trackInactive = inactiveColor ?? (isDark ? AppColors.surfaceAlt : const Color(0xFFDCE3EA));

    Widget switchWidget = Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: trackActive,
      inactiveTrackColor: trackInactive,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return isDark ? AppColors.textMuted : const Color(0xFF93A0AF);
      }),
    );

    if (label != null) {
      return GestureDetector(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimary : const Color(0xFF151922),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMuted : const Color(0xFF93A0AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            switchWidget,
          ],
        ),
      );
    }

    return switchWidget;
  }
}
