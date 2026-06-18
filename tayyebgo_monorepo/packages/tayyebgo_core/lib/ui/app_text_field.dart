import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';
import '../presentation/theme/app_motion.dart';

/// TGF = TayyebGoField — Floating label text input
class TGF extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const TGF({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<TGF> createState() => _TGFState();
}

class _TGFState extends State<TGF> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _glowAnimation;
  bool _isFocused = false;
  bool _obscureVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureVisible = !widget.obscureText;
    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_isFocused) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brInput,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: (hasError ? AppColors.glowError : AppColors.glowPrimary)
                          .withValues(alpha: _glowAnimation.value * 0.5),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ]
                : [],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brInput,
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : _isFocused
                        ? AppColors.primary
                        : AppColors.border,
                width: _isFocused ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText && !_obscureVisible,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                counterText: '',
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _isFocused
                            ? AppColors.primary
                            : AppColors.textMuted,
                      )
                    : null,
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscureVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureVisible = !_obscureVisible),
                      )
                    : widget.suffix,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _isFocused
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (!hasError && widget.helperText != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.helperText!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Backward compatibility alias
typedef AppTextField = TGF;
