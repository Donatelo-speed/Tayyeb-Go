import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';
import 'cached_image.dart';

/// TGAvatar = TayyebGoAvatar — Image with fallback and status indicators
enum TGAvatarSize { xs, sm, md, lg, xl }

class TGAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final TGAvatarSize size;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showOnline;
  final String? role;

  const TGAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = TGAvatarSize.md,
    this.backgroundColor,
    this.borderColor,
    this.showOnline = false,
    this.role,
  });

  double get _size => switch (size) {
        TGAvatarSize.xs => 28,
        TGAvatarSize.sm => 36,
        TGAvatarSize.md => 44,
        TGAvatarSize.lg => 56,
        TGAvatarSize.xl => 72,
      };

  double get _fontSize => switch (size) {
        TGAvatarSize.xs => 10,
        TGAvatarSize.sm => 12,
        TGAvatarSize.md => 14,
        TGAvatarSize.lg => 18,
        TGAvatarSize.xl => 24,
      };

  double get _onlineDotSize => switch (size) {
        TGAvatarSize.xs => 6,
        TGAvatarSize.sm => 8,
        TGAvatarSize.md => 10,
        TGAvatarSize.lg => 12,
        TGAvatarSize.xl => 14,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.surfaceAlt : AppColors.primaryLight);
    final displayInitials = initials ?? '?';

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 2)
                  : null,
            ),
            child: imageUrl != null
                ? ClipOval(
                    child: CachedImage(
                      imageUrl: imageUrl!,
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      displayInitials,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          if (showOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _onlineDotSize,
                height: _onlineDotSize,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.surface : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          if (role != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _roleColor(role!),
                  borderRadius: AppRadius.brBadge,
                ),
                child: Text(
                  role!.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'superadmin':
        return AppColors.premium;
      case 'driver':
        return AppColors.warning;
      case 'restaurantowner':
      case 'cashier':
        return AppColors.emerald;
      default:
        return AppColors.primary;
    }
  }
}

// Backward compatibility alias
typedef AppAvatar = TGAvatar;
