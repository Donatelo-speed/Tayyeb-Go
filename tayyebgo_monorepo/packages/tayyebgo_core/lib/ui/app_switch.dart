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
    final trackActive = activeColor ?? AppColors.primary;
    final trackInactive = inactiveColor ?? AppColors.surfaceAlt;

    Widget switchWidget = Semantics(
      toggled: value,
      label: label ?? 'Toggle',
      child: Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: trackActive,
      inactiveTrackColor: trackInactive,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.textMuted;
      }),
      ),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
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
