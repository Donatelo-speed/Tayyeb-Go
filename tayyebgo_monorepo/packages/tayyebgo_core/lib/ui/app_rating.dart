import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';

/// TGRating — Star rating display and input
class TGRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double starSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;
  final String? label;
  final bool showValue;

  const TGRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 20,
    this.activeColor,
    this.inactiveColor,
    this.interactive = false,
    this.onRatingChanged,
    this.label,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.amber;
    final inactive = inactiveColor ?? AppColors.surfaceAlt;

    return Semantics(
      label: 'Rating: ${rating.toStringAsFixed(1)} out of $maxRating',
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starValue = index + 1.0;
          final isFilled = rating >= starValue;
          final isHalf = !isFilled && rating >= starValue - 0.5;

          return GestureDetector(
            onTap: interactive && onRatingChanged != null
                ? () => onRatingChanged!(starValue)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                isFilled
                    ? Icons.star_rounded
                    : isHalf
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                size: starSize,
                color: (isFilled || isHalf) ? active : inactive,
              ),
            ),
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: starSize * 0.7,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: starSize * 0.6,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
      ),
    );
  }
}

/// TGRatingBar — Full-width rating bar (horizontal stars)
class TGRatingBar extends StatelessWidget {
  final double rating;
  final int maxRating;
  final ValueChanged<double>? onRatingChanged;
  final double starSize;

  const TGRatingBar({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.onRatingChanged,
    this.starSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return TGRating(
      rating: rating,
      maxRating: maxRating,
      starSize: starSize,
      interactive: onRatingChanged != null,
      onRatingChanged: onRatingChanged,
    );
  }
}
