import 'package:flutter/material.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_gradients.dart';
import '../presentation/theme/app_radius.dart';
import '../presentation/theme/app_motion.dart';

/// TGB = TayyebGoButton — Unified button system
enum TGBVariant { primary, secondary, ghost, destructive, icon, social }

class TGB extends StatefulWidget {
  final String? label;
  final VoidCallback? onPressed;
  final TGBVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isExpanded;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? socialLabel;
  final Widget? socialIcon;

  const TGB({
    super.key,
    this.label,
    this.onPressed,
    this.variant = TGBVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.socialLabel,
    this.socialIcon,
  });

  // ── Named constructors ──
  const TGB.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = true,
    this.width,
    this.height,
  })  : variant = TGBVariant.primary,
        backgroundColor = null,
        foregroundColor = null,
        socialLabel = null,
        socialIcon = null;

  const TGB.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = true,
    this.width,
    this.height,
  })  : variant = TGBVariant.secondary,
        backgroundColor = null,
        foregroundColor = null,
        socialLabel = null,
        socialIcon = null;

  const TGB.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
  })  : variant = TGBVariant.ghost,
        trailingIcon = null,
        isExpanded = false,
        backgroundColor = null,
        foregroundColor = null,
        socialLabel = null,
        socialIcon = null;

  const TGB.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.width,
    this.height,
  })  : variant = TGBVariant.destructive,
        trailingIcon = null,
        backgroundColor = null,
        foregroundColor = null,
        socialLabel = null,
        socialIcon = null;

  const TGB.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
  })  : variant = TGBVariant.icon,
        label = null,
        trailingIcon = null,
        isLoading = false,
        isExpanded = false,
        socialLabel = null,
        socialIcon = null;

  const TGB.social({
    super.key,
    required this.label,
    required this.onPressed,
    this.socialIcon,
    this.isExpanded = true,
    this.width,
  })  : variant = TGBVariant.social,
        icon = null,
        trailingIcon = null,
        isLoading = false,
        backgroundColor = null,
        foregroundColor = null,
        socialLabel = null,
        height = null;

  @override
  State<TGB> createState() => _TGBState();
}

class _TGBState extends State<TGB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.onPressed == null || widget.isLoading;
    final btnHeight = widget.height ?? (widget.variant == TGBVariant.icon ? 48.0 : 52.0);

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label ?? (widget.variant == TGBVariant.icon ? 'Icon button' : null),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _controller.forward(),
        onTapUp: disabled ? null : (_) => _controller.reverse(),
        onTapCancel: disabled ? null : () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: _buildButton(isDark, disabled, btnHeight),
        ),
      ),
    );
  }

  Widget _buildButton(bool isDark, bool disabled, double btnHeight) {
    switch (widget.variant) {
      case TGBVariant.primary:
        return _buildPrimary(isDark, disabled, btnHeight);
      case TGBVariant.secondary:
        return _buildSecondary(isDark, disabled, btnHeight);
      case TGBVariant.ghost:
        return _buildGhost(isDark, disabled, btnHeight);
      case TGBVariant.destructive:
        return _buildDestructive(isDark, disabled, btnHeight);
      case TGBVariant.icon:
        return _buildIconButton(isDark, disabled, btnHeight);
      case TGBVariant.social:
        return _buildSocial(isDark, disabled, btnHeight);
    }
  }

  Widget _buildPrimary(bool isDark, bool disabled, double btnHeight) {
    return Container(
      width: widget.width ?? (widget.isExpanded ? double.infinity : null),
      height: btnHeight,
      decoration: BoxDecoration(
        gradient: disabled ? null : AppGradients.primaryGradientHorizontal,
        color: disabled
            ? (isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.5))
            : null,
        borderRadius: AppRadius.brButton,
        boxShadow: disabled ? [] : [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: AppRadius.brButton,
          child: _buildContent(Colors.white),
        ),
      ),
    );
  }

  Widget _buildSecondary(bool isDark, bool disabled, double btnHeight) {
    return Container(
      width: widget.width ?? (widget.isExpanded ? double.infinity : null),
      height: btnHeight,
      decoration: BoxDecoration(
        color: disabled
            ? (isDark ? AppColors.primarySoft.withValues(alpha: 0.2) : AppColors.primarySoft.withValues(alpha: 0.5))
            : (isDark ? AppColors.primarySoft.withValues(alpha: 0.15) : AppColors.primarySoft),
        borderRadius: AppRadius.brButton,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: AppRadius.brButton,
          child: _buildContent(disabled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildGhost(bool isDark, bool disabled, double btnHeight) {
    return SizedBox(
      width: widget.width,
      height: btnHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: AppRadius.brButton,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildContent(disabled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildDestructive(bool isDark, bool disabled, double btnHeight) {
    return Container(
      width: widget.width ?? (widget.isExpanded ? double.infinity : null),
      height: btnHeight,
      decoration: BoxDecoration(
        color: disabled
            ? AppColors.error.withValues(alpha: 0.3)
            : AppColors.error.withValues(alpha: 0.9),
        borderRadius: AppRadius.brButton,
        boxShadow: disabled ? [] : [
          BoxShadow(
            color: AppColors.glowError,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: AppRadius.brButton,
          child: _buildContent(Colors.white),
        ),
      ),
    );
  }

  Widget _buildIconButton(bool isDark, bool disabled, double btnHeight) {
    return Container(
      width: widget.width ?? btnHeight,
      height: btnHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surfaceAlt,
        borderRadius: AppRadius.brAvatar,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: AppRadius.brAvatar,
          child: Icon(
            widget.icon,
            size: 22,
            color: widget.foregroundColor ?? AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSocial(bool isDark, bool disabled, double btnHeight) {
    return Container(
      width: widget.width ?? (widget.isExpanded ? double.infinity : null),
      height: btnHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAlt : AppColors.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: AppRadius.brButton,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.socialIcon != null) ...[
                widget.socialIcon!,
                const SizedBox(width: 10),
              ],
              Text(
                widget.socialLabel ?? widget.label ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fgColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: fgColor.withValues(alpha: 0.8),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fgColor),
          const SizedBox(width: 8),
        ],
        if (widget.label != null)
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: fgColor,
              letterSpacing: 0.2,
            ),
          ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: 18, color: fgColor),
        ],
      ],
    );
  }
}

// Backward compatibility alias
typedef AppButton = TGB;
typedef AppButtonVariant = TGBVariant;
