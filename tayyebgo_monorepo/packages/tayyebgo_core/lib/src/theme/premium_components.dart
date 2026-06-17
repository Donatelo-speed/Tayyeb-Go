import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumCard — Glassmorphism card with backdrop blur
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final bool enableGlow;
  final Color? glowColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = PremiumTheme.radiusMd,
    this.blur = 12,
    this.enableGlow = false,
    this.glowColor,
    this.backgroundColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final bgColor = backgroundColor ??
        (dark ? PremiumTheme.darkGlass : PremiumTheme.lightGlass);
    final borderColor = dark
        ? PremiumTheme.darkGlassBorder
        : PremiumTheme.lightGlassBorder;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? bgColor : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: enableGlow
                ? [
                    BoxShadow(
                      color: (glowColor ?? PremiumTheme.primary)
                          .withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ]
                : PremiumTheme.shadowMd,
          ),
          padding: padding ?? const EdgeInsets.all(PremiumTheme.space4),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumButton — Gradient button with ripple, glow, and press effects
/// ═══════════════════════════════════════════════════════════════════════════
enum PremiumButtonVariant { filled, outlined, ghost, gradient }

enum PremiumButtonSize { sm, md, lg }

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PremiumButtonVariant variant;
  final PremiumButtonSize size;
  final Gradient? gradient;
  final bool isLoading;
  final bool fullWidth;
  final Color? color;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PremiumButtonVariant.filled,
    this.size = PremiumButtonSize.md,
    this.gradient,
    this.isLoading = false,
    this.fullWidth = false,
    this.color,
  });

  const PremiumButton.gradient({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = PremiumButtonSize.md,
    this.gradient,
    this.isLoading = false,
    this.fullWidth = false,
    this.color,
  })  : variant = PremiumButtonVariant.gradient,
        super();

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PremiumTheme.durationFast,
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final bgColor = dark ? PremiumTheme.darkSurfaceAlt : PremiumTheme.lightSurfaceAlt;

    double horizontal, vertical, fontSize;
    switch (widget.size) {
      case PremiumButtonSize.sm:
        horizontal = 16;
        vertical = 10;
        fontSize = 13;
        break;
      case PremiumButtonSize.md:
        horizontal = 24;
        vertical = 14;
        fontSize = 14;
        break;
      case PremiumButtonSize.lg:
        horizontal = 32;
        vertical = 18;
        fontSize = 16;
        break;
    }

    Widget buildLabel() {
      if (widget.isLoading) {
        return SizedBox(
          width: fontSize,
          height: fontSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.variant == PremiumButtonVariant.filled ||
                      widget.variant == PremiumButtonVariant.gradient
                  ? Colors.white
                  : PremiumTheme.primary,
            ),
          ),
        );
      }

      final children = <Widget>[];
      if (widget.icon != null) {
        children.add(Icon(widget.icon, size: fontSize + 2));
        children.add(const SizedBox(width: 8));
      }
      children.add(Text(widget.label, style: TextStyle(fontSize: fontSize)));
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: buildLabel(),
    );

    Widget button;
    switch (widget.variant) {
      case PremiumButtonVariant.filled:
        final btnColor = widget.color ?? PremiumTheme.primary;
        button = Material(
          color: btnColor,
          borderRadius: PremiumTheme.brButton,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: PremiumTheme.brButton,
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: DefaultTextStyle(
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              child: content,
            ),
          ),
        );
        break;

      case PremiumButtonVariant.outlined:
        final btnColor = widget.color ?? PremiumTheme.primary;
        button = Material(
          color: Colors.transparent,
          borderRadius: PremiumTheme.brButton,
          shape: RoundedRectangleBorder(
            borderRadius: PremiumTheme.brButton,
            side: BorderSide(color: btnColor, width: 1.5),
          ),
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: PremiumTheme.brButton,
            splashColor: btnColor.withValues(alpha: 0.1),
            highlightColor: btnColor.withValues(alpha: 0.05),
            child: DefaultTextStyle(
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: btnColor,
              ),
              child: content,
            ),
          ),
        );
        break;

      case PremiumButtonVariant.ghost:
        button = Material(
          color: Colors.transparent,
          borderRadius: PremiumTheme.brButton,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: PremiumTheme.brButton,
            splashColor: bgColor.withValues(alpha: 0.3),
            child: DefaultTextStyle(
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: widget.color ?? PremiumTheme.primary,
              ),
              child: content,
            ),
          ),
        );
        break;

      case PremiumButtonVariant.gradient:
        button = Container(
          decoration: BoxDecoration(
            gradient: widget.gradient ?? PremiumTheme.primaryGradient,
            borderRadius: PremiumTheme.brButton,
            boxShadow: PremiumTheme.glowShadowPrimary,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: PremiumTheme.brButton,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: PremiumTheme.brButton,
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: DefaultTextStyle(
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                child: content,
              ),
            ),
          ),
        );
        break;
    }

    button = AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: button,
    );

    button = GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: button,
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumInput — Floating label with focus glow
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? error;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const PremiumInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.error,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<PremiumInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: PremiumTheme.durationNormal,
    );
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final bgColor = dark ? PremiumTheme.darkSurfaceAlt : PremiumTheme.lightSurfaceAlt;
    final textColor = dark ? PremiumTheme.darkTextPrimary : PremiumTheme.lightTextPrimary;
    final mutedColor = dark ? PremiumTheme.darkTextMuted : PremiumTheme.lightTextMuted;
    final borderColor = widget.error != null
        ? PremiumTheme.error
        : (dark ? PremiumTheme.darkBorder : PremiumTheme.lightBorder);
    final focusColor = PremiumTheme.primary;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        final glowOpacity = _glowAnim.value * 0.15;
        return Container(
          decoration: BoxDecoration(
            borderRadius: PremiumTheme.brInput,
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: focusColor.withValues(alpha: glowOpacity),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: GoogleFonts.inter(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20, color: mutedColor)
                  : null,
              suffixIcon: widget.suffix,
              filled: true,
              fillColor: bgColor,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: PremiumTheme.brInput,
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: PremiumTheme.brInput,
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: PremiumTheme.brInput,
                borderSide: const BorderSide(
                    color: PremiumTheme.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: PremiumTheme.brInput,
                borderSide: const BorderSide(color: PremiumTheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: PremiumTheme.brInput,
                borderSide: const BorderSide(
                    color: PremiumTheme.error, width: 1.5),
              ),
              labelStyle: GoogleFonts.inter(
                  fontSize: 14, color: mutedColor),
              hintStyle: GoogleFonts.inter(
                  fontSize: 14, color: mutedColor.withValues(alpha: 0.6)),
              errorStyle: GoogleFonts.inter(
                  fontSize: 12, color: PremiumTheme.error),
            ),
            onFocused: (focused) {
              setState(() => _focused = focused);
              if (focused) {
                _glowController.forward();
              } else {
                _glowController.reverse();
              }
            },
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumBadge — Status indicator
/// ═══════════════════════════════════════════════════════════════════════════
enum PremiumBadgeVariant { filled, outlined, soft }

class PremiumBadge extends StatelessWidget {
  final String label;
  final PremiumBadgeVariant variant;
  final Color color;
  final bool small;

  const PremiumBadge({
    super.key,
    required this.label,
    this.variant = PremiumBadgeVariant.soft,
    this.color = PremiumTheme.primary,
    this.small = false,
  });

  const PremiumBadge.success({
    super.key,
    required this.label,
    this.variant = PremiumBadgeVariant.soft,
    this.small = false,
  }) : color = PremiumTheme.accent;

  const PremiumBadge.error({
    super.key,
    required this.label,
    this.variant = PremiumBadgeVariant.soft,
    this.small = false,
  }) : color = PremiumTheme.error;

  const PremiumBadge.warning({
    super.key,
    required this.label,
    this.variant = PremiumBadgeVariant.soft,
    this.small = false,
  }) : color = PremiumTheme.warning;

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final fontSize = small ? 10.0 : 11.0;
    final vPadding = small ? 3.0 : 5.0;
    final hPadding = small ? 8.0 : 12.0;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    switch (variant) {
      case PremiumBadgeVariant.filled:
        bgColor = color;
        fgColor = Colors.white;
        borderColor = color;
        break;
      case PremiumBadgeVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = color;
        borderColor = color;
        break;
      case PremiumBadgeVariant.soft:
        bgColor = color.withValues(alpha: 0.15);
        fgColor = color;
        borderColor = color.withValues(alpha: 0.3);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: PremiumTheme.brFull,
        border: variant == PremiumBadgeVariant.outlined
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumAvatar — Avatar with online dot and role badge
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final bool showOnline;
  final String? roleLabel;
  final Color? roleColor;
  final VoidCallback? onTap;

  const PremiumAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 44,
    this.showOnline = false,
    this.roleLabel,
    this.roleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final bgColor = dark ? PremiumTheme.darkSurfaceAlt : PremiumTheme.lightSurfaceAlt;
    final textColor = dark ? PremiumTheme.darkTextPrimary : PremiumTheme.lightTextPrimary;
    final dotSize = size * 0.24;
    final initialFontSize = size * 0.36;

    Widget avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: dark ? PremiumTheme.darkBorder : PremiumTheme.lightBorder,
              width: 2,
            ),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    initials ?? '?',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: initialFontSize,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                )
              : null,
        ),
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: PremiumTheme.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dark ? PremiumTheme.darkSurface : PremiumTheme.lightSurface,
                  width: 2,
                ),
              ),
            ),
          ),
        if (roleLabel != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.12,
                vertical: size * 0.04,
              ),
              decoration: BoxDecoration(
                color: roleColor ?? PremiumTheme.secondary,
                borderRadius: PremiumTheme.brFull,
                border: Border.all(
                  color:
                      dark ? PremiumTheme.darkSurface : PremiumTheme.lightSurface,
                  width: 1.5,
                ),
              ),
              child: Text(
                roleLabel!,
                style: GoogleFonts.inter(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumChip — Filter / selection chip
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const PremiumChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final chipColor = color ?? PremiumTheme.primary;
    final bgColor = selected
        ? chipColor.withValues(alpha: 0.15)
        : (dark ? PremiumTheme.darkSurfaceAlt : PremiumTheme.lightSurfaceAlt);
    final fgColor = selected
        ? chipColor
        : (dark ? PremiumTheme.darkTextSecondary : PremiumTheme.lightTextSecondary);
    final borderColor = selected
        ? chipColor.withValues(alpha: 0.3)
        : (dark ? PremiumTheme.darkBorder : PremiumTheme.lightBorder);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PremiumTheme.durationFast,
        padding: const EdgeInsets.symmetric(
            horizontal: PremiumTheme.space3, vertical: PremiumTheme.space2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: PremiumTheme.brFull,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumBottomSheet — Draggable sheet with snap points
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showDragHandle;
  final double initialChildSize;
  final List<double> snapPoints;

  const PremiumBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.initialChildSize = 0.5,
    this.snapPoints = const [0.25, 0.5, 0.9],
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumBottomSheet(
        title: title,
        showDragHandle: showDragHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final bgColor = dark ? PremiumTheme.darkSurface : PremiumTheme.lightSurface;
    final textColor =
        dark ? PremiumTheme.darkTextPrimary : PremiumTheme.lightTextPrimary;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: snapPoints.first,
      maxChildSize: snapPoints.last,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(PremiumTheme.radiusXl),
            ),
            boxShadow: PremiumTheme.shadowXl,
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              if (showDragHandle)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: dark
                          ? PremiumTheme.darkTextMuted
                          : PremiumTheme.lightTextMuted,
                      borderRadius: PremiumTheme.brFull,
                    ),
                  ),
                ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PremiumTheme.space4, vertical: PremiumTheme.space2),
                  child: Text(
                    title!,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              child,
            ],
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumDialog — Animated entrance dialog
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const PremiumDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.showCloseButton = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool showCloseButton = true,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: PremiumTheme.durationNormal,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: PremiumTheme.springSoft,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return PremiumDialog(
          title: title,
          content: content,
          actions: actions,
          showCloseButton: showCloseButton,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final bgColor = dark ? PremiumTheme.darkSurface : PremiumTheme.lightSurface;
    final textColor =
        dark ? PremiumTheme.darkTextPrimary : PremiumTheme.lightTextPrimary;

    return Dialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: PremiumTheme.brDialog,
      ),
      child: Padding(
        padding: const EdgeInsets.all(PremiumTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCloseButton || title != null)
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  if (showCloseButton)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: dark
                            ? PremiumTheme.darkTextMuted
                            : PremiumTheme.lightTextMuted,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: PremiumTheme.space4),
            content,
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: PremiumTheme.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumLoading — Skeleton shimmer placeholder
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const PremiumLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = PremiumTheme.radiusSm,
  });

  @override
  State<PremiumLoading> createState() => _PremiumLoadingState();
}

class _PremiumLoadingState extends State<PremiumLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final baseColor = dark ? PremiumTheme.darkSurfaceAlt : PremiumTheme.lightSurfaceAlt;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PremiumEmptyState — Illustration + action
/// ═══════════════════════════════════════════════════════════════════════════
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dark = PremiumTheme.isDark(context);
    final textColor =
        dark ? PremiumTheme.darkTextPrimary : PremiumTheme.lightTextPrimary;
    final mutedColor = dark
        ? PremiumTheme.darkTextSecondary
        : PremiumTheme.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PremiumTheme.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: PremiumTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: PremiumTheme.primary,
              ),
            ),
            const SizedBox(height: PremiumTheme.space5),
            Text(
              title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PremiumTheme.space2),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: mutedColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: PremiumTheme.space6),
              PremiumButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
