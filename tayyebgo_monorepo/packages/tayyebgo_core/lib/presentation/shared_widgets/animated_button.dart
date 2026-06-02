import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final List<BoxShadow>? boxShadow;
  final double? fontSize;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.borderRadius = 12,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.boxShadow,
    this.fontSize,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, __) => Transform.scale(
        scale: widget.isLoading ? 1.0 : _scaleAnim.value,
        child: GestureDetector(
          onTap: _disabled ? null : widget.onPressed,
          onTapDown: _disabled ? null : (_) => _ctrl.forward(),
          onTapUp: _disabled ? null : (_) => _ctrl.reverse(),
          onTapCancel: () => _ctrl.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width ?? double.infinity,
            height: widget.height,
            padding: widget.padding ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              color: widget.isLoading
                  ? (widget.backgroundColor ?? AppColors.primary).withValues(alpha: 0.6)
                  : (widget.backgroundColor ?? AppColors.primary),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: widget.boxShadow ?? [
                BoxShadow(
                  color: (widget.backgroundColor ?? AppColors.primary).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : DefaultTextStyle(
                      style: TextStyle(
                        color: widget.foregroundColor ?? Colors.white,
                        fontSize: widget.fontSize ?? 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      child: widget.child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedTextButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final double? fontSize;

  const AnimatedTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.fontSize,
  });

  @override
  State<AnimatedTextButton> createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<AnimatedTextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _opacity = Tween(begin: 1.0, end: 0.5).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: GestureDetector(
          onTap: widget.onPressed,
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) => _ctrl.reverse(),
          onTapCancel: () => _ctrl.reverse(),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.color ?? AppColors.primary,
              fontSize: widget.fontSize ?? 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
