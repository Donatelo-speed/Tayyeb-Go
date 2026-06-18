import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionPaymentSheet extends StatefulWidget {
  final SubscriptionPlanType plan;
  final String userId;

  const SubscriptionPaymentSheet({
    super.key,
    required this.plan,
    required this.userId,
  });

  @override
  State<SubscriptionPaymentSheet> createState() => _SubscriptionPaymentSheetState();
}

class _SubscriptionPaymentSheetState extends State<SubscriptionPaymentSheet> {
  late final String _referenceCode;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _referenceCode = _generateReferenceCode();
  }

  String _generateReferenceCode() {
    final rng = Random();
    final num = rng.nextInt(900000) + 100000;
    return 'TG-${num}';
  }

  Future<void> _confirmPayment() async {
    setState(() => _isProcessing = true);
    try {
      final success = await context.read<SubscriptionProvider>().subscribe(
        widget.userId,
        widget.plan,
        _referenceCode,
      );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'TayyebGo ${widget.plan.displayName} activated!',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          context.showError('Subscription activation failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: AppRadius.brXs,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Payment Instructions', style: TayyebGoTheme.heading3),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: TayyebGoTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ShamCash Payment',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _instructionRow(
                  '1.',
                  'Send ${widget.plan.priceDisplay} to TayyebGo account:',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: AppRadius.brMd,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'TayyebGo Official',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                _instructionRow(
                  '2.',
                  'Use this reference code:',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Text(
                    _referenceCode,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                _instructionRow(
                  '3.',
                  'Tap "I\'ve Paid" after completing the transfer.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your subscription will be activated within 5 minutes after payment confirmation.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.brMd,
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'I\'ve Paid',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _instructionRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
