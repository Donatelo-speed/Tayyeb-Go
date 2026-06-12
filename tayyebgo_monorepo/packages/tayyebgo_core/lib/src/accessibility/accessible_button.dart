import 'package:flutter/material.dart';

/// Accessible button that meets WCAG minimum touch target (48x48).
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isExpanded;
  final double minHeight;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.isExpanded = false,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    final btn = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(isExpanded ? double.infinity : 0, minHeight),
              backgroundColor: color,
              foregroundColor: color != null ? Colors.white : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(isExpanded ? double.infinity : 0, minHeight),
              backgroundColor: color,
              foregroundColor: color != null ? Colors.white : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(label),
          );

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: btn,
    );
  }
}

/// Accessible icon button with minimum 48x48 touch target.
class AccessibleIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const AccessibleIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        enabled: onPressed != null,
        child: IconButton(
          onPressed: onPressed,
          iconSize: size,
          padding: const EdgeInsets.all(12),
          icon: Icon(icon, color: color),
        ),
      ),
    );
  }
}
