import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';

/// Generates a 4-digit delivery PIN for order verification.
/// Stores it in the order document under `deliveryPin`.
class DeliveryPinGenerator {
  static String generate() {
    final rng = Random.secure();
    return (1000 + rng.nextInt(9000)).toString();
  }

  /// Sets the delivery PIN on an order document (call once at order creation).
  static Future<void> setPin(String orderId) async {
    final pin = generate();
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'deliveryPin': pin,
      'deliveryPinSetAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Bottom sheet shown to the driver to enter the delivery PIN before completing delivery.
class DeliveryPinVerificationSheet extends StatefulWidget {
  final String orderId;
  final VoidCallback onVerified;

  const DeliveryPinVerificationSheet({
    super.key,
    required this.orderId,
    required this.onVerified,
  });

  @override
  State<DeliveryPinVerificationSheet> createState() => _DeliveryPinVerificationSheetState();
}

class _DeliveryPinVerificationSheetState extends State<DeliveryPinVerificationSheet> {
  final _pinController = TextEditingController();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'Enter the 4-digit PIN');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      final storedPin = doc.data()?['deliveryPin'] as String?;

      if (storedPin == null) {
        setState(() {
          _verifying = false;
          _error = 'No PIN found for this order. Contact support.';
        });
        return;
      }

      if (pin == storedPin) {
        // PIN verified — mark the order with verification
        await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
          'deliveryPinVerified': true,
          'deliveryPinVerifiedAt': FieldValue.serverTimestamp(),
          'deliveryVerifiedBy': AuthProvider.instance?.user?.id ?? 'unknown',
        });

        if (mounted) {
          Navigator.of(context).pop(true);
          widget.onVerified();
        }
      } else {
        setState(() {
          _verifying = false;
          _error = 'Incorrect PIN. Ask the customer for the correct code.';
        });
      }
    } catch (e) {
      setState(() {
        _verifying = false;
        _error = 'Verification failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: AppRadius.brSm,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.brMd,
                ),
                child: const Icon(Icons.pin_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Verification', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Ask the customer for their 4-digit PIN', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              counterText: '',
              hintText: '----',
              hintStyle: GoogleFonts.inter(color: AppColors.border, fontSize: 32, letterSpacing: 16),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: AppRadius.brLg,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.brLg,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.brLg,
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.brLg,
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _verifying ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.success.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                elevation: 0,
              ),
              child: _verifying
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Verify & Complete Delivery', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
