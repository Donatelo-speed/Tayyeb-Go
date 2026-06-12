import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'stripe_wrapper_stub.dart' if (dart.library.io) 'stripe_wrapper_native.dart';

class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final _amountCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  static const _presets = [5, 10, 20, 50, 100];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Top Up Wallet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('Add Funds', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 12),
                Text(
                  _amountCtrl.text.isEmpty ? '\$0.00' : '\$${double.tryParse(_amountCtrl.text)?.toStringAsFixed(2) ?? '0.00'}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 42, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((amt) {
              return GestureDetector(
                onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text('\$$amt', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: context.textPrimaryColor)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 18),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Custom amount',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.inter(color: context.errorColor, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _topUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Top Up', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Powered by Stripe. Your card details are never stored on our servers.',
            style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _topUp() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount < 1) {
      setState(() => _error = 'Minimum top-up is \$1.00');
      return;
    }
    if (amount > 1000) {
      setState(() => _error = 'Maximum top-up is \$1,000');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final amountInCents = (amount * 100).round();
      final result = await StripeCheckoutService.createTopUpIntent(amountInCents);
      if (!result.success || result.clientSecret == null) {
        setState(() {
          _error = result.errorMessage ?? 'Failed to initiate payment';
          _isProcessing = false;
        });
        return;
      }

      final stripe = createCoreStripeWrapper();
      await stripe.initPaymentSheet(
        clientSecret: result.clientSecret!,
        merchantDisplayName: 'TayyebGo Wallet',
      );
      await stripe.presentPaymentSheet();

      final confirmed = await StripeCheckoutService.confirmTopUp(result.paymentIntentId!);
      if (!confirmed) {
        setState(() {
          _error = 'Payment was processed but wallet update failed. Contact support.';
          _isProcessing = false;
        });
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\$${amount.toStringAsFixed(2)} added to wallet!', style: GoogleFonts.inter()),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      final msg = e.toString().contains('cancelled') ? 'Payment was cancelled' : e.toString();
      if (mounted) {
        setState(() {
          _error = msg;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Payment failed: $e';
          _isProcessing = false;
        });
      }
    }
  }
}
