import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/app_radius.dart';

/// TGSearchBar — Themed search input with icon and clear button
class TGSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;
  final FocusNode? focusNode;

  const TGSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.controller,
    this.readOnly = false,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<TGSearchBar> createState() => _TGSearchBarState();
}

class _TGSearchBarState extends State<TGSearchBar> {
  late TextEditingController _ctrl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
    _ctrl.addListener(_onTextChanged);
    _hasText = _ctrl.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _ctrl.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAlt : const Color(0xFFF5F6F8),
          borderRadius: AppRadius.brInput,
          border: Border.all(
            color: isDark ? AppColors.border : const Color(0xFFE8EDF2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.prefixIcon ?? Icons.search_rounded,
              size: 20,
              color: isDark ? AppColors.textMuted : const Color(0xFF93A0AF),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                readOnly: widget.readOnly,
                autofocus: widget.autofocus,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimary : const Color(0xFF151922),
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppColors.textMuted : const Color(0xFF93A0AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (widget.suffix != null) widget.suffix!,
            if (_hasText && widget.onChanged != null)
              GestureDetector(
                onTap: () {
                  _ctrl.clear();
                  widget.onChanged?.call('');
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : const Color(0xFFE8EDF2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isDark ? AppColors.textMuted : const Color(0xFF93A0AF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
