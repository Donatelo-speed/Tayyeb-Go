import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class OtpField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final TextEditingController? controller;
  final int resendSeconds;

  const OtpField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.controller,
    this.resendSeconds = 60,
  });

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _controllers.first.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    for (final n in _focusNodes) {
      n.dispose();
    }
    for (final c in _controllers) {
      c.removeListener(_onInputChanged);
      c.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onInputChanged() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  void startCountdown() {
    _remaining = widget.resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        if (mounted) setState(() {});
        return;
      }
      if (mounted) setState(() => _remaining--);
    });
    if (mounted) setState(() {});
  }

  bool get isCountdownActive => _remaining > 0;
  String get remainingText {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void reset() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    _remaining = 0;
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.length, (i) => _buildDigitField(i)),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isCountdownActive)
          Text(
            'Resend code in $remainingText',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          )
        else
          GestureDetector(
            onTap: () {
              reset();
              startCountdown();
            },
            child: Text(
              'Resend code',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDigitField(int i) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < widget.length - 1) {
            _focusNodes[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
          }
          _onInputChanged();
        },
      ),
    );
  }
}
