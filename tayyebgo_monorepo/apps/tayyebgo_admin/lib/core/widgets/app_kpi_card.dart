import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AppKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String? subtitle;
  final Widget? trailing;
  final String? trend;
  final bool trendUp;
  final VoidCallback? onTap;
  final bool flat;

  const AppKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.trailing,
    this.trend,
    this.trendUp = true,
    this.onTap,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(20),
      decoration: flat
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.brCard,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconBadge(context, icon),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.displaySmall.copyWith(
                color: flat ? context.textPrimaryColor : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.body.copyWith(
              color: flat ? context.textSecondaryColor : Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (trend != null) ...[
                Icon(
                  trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: flat
                      ? (trendUp ? context.successColor : context.errorColor)
                      : Colors.white.withValues(alpha: 0.9),
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  trend!,
                  style: AppTypography.labelSmall.copyWith(
                    color: flat
                        ? (trendUp ? context.successColor : context.errorColor)
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (subtitle != null)
                Flexible(
                  child: Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: flat ? context.textMutedColor : Colors.white.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ]),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: card,
      ),
    );
  }

  Widget _iconBadge(BuildContext context, IconData icon) {
    if (flat) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: gradient.first.withValues(alpha: 0.12),
          borderRadius: AppRadius.brSm,
        ),
        child: Icon(icon, color: gradient.first, size: 20),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.brSm,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
