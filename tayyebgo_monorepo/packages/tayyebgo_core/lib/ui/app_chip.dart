import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';

/// TGChip — Filter, action, and input chips
enum TGChipVariant { filter, action, input }

class TGChip extends StatelessWidget {
  final String label;
  final TGChipVariant variant;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final bool small;

  const TGChip({
    super.key,
    required this.label,
    this.variant = TGChipVariant.filter,
    this.selected = false,
    this.onTap,
    this.onDelete,
    this.icon,
    this.color,
    this.backgroundColor,
    this.small = false,
  });

  const TGChip.filter({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.color,
    this.backgroundColor,
    this.small = false,
  })  : variant = TGChipVariant.filter,
        onDelete = null;

  const TGChip.action({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color,
    this.backgroundColor,
    this.small = false,
  })  : variant = TGChipVariant.action,
        selected = false,
        onDelete = null;

  const TGChip.input({
    super.key,
    required this.label,
    this.onDelete,
    this.icon,
    this.color,
    this.backgroundColor,
    this.small = false,
  })  : variant = TGChipVariant.input,
        selected = false,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = color ?? (selected ? AppColors.primary : (isDark ? AppColors.textSecondary : const Color(0xFF6B7686)));
    final bgColor = backgroundColor ?? (selected
        ? AppColors.primarySoft
        : (isDark ? AppColors.surfaceAlt : const Color(0xFFF0F2F5)));

    final fontSize = small ? 11.0 : 13.0;
    final hPad = small ? 8.0 : 12.0;
    final vPad = small ? 4.0 : 6.0;

    Widget chip = Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.brChip,
        border: variant == TGChipVariant.filter && selected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 14, color: fgColor),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: fgColor,
            ),
          ),
          if (onDelete != null) ...[
            SizedBox(width: small ? 4 : 6),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded, size: small ? 12 : 14, color: fgColor),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      chip = GestureDetector(onTap: onTap, child: chip);
    }

    return chip;
  }
}

/// TGCategoryChip — Pre-styled category chip with icon
class TGCategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const TGCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TGChip.filter(
      label: label,
      selected: selected,
      onTap: onTap,
      icon: icon,
    );
  }
}
