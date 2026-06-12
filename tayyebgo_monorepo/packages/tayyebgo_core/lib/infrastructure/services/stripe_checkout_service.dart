import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/services/i_payment_service.dart';
import '../../domain/value_objects/money.dart';
import 'commission_calculator.dart';

class StripeCheckoutService implements IPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CommissionCalculator _commission = CommissionCalculator();

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  /// Create a real Stripe PaymentIntent via Cloud Function.
  /// Returns [PaymentIntentResult] with the clientSecret for Flutter Stripe SDK.
  @override
  Future<PaymentIntentResult> createPaymentIntent(PaymentIntentRequest request) async {
    final now = DateTime.now();
    final txnId = 'stripe_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final commission = _commission.calculate(request.amount, request.commissionPercent);

    try {
      final callable = _functions.httpsCallable('createStripePaymentIntent');
      final result = await callable.call({
        'amountInCents': request.amount.amountInCents,
        'currency': request.currency,
        'orderId': request.orderId,
        'metadata': {
          'commissionPercent': request.commissionPercent.toString(),
          'restaurantId': request.restaurantId ?? '',
        },
      });

      final clientSecret = result.data['clientSecret'] as String?;
      final paymentIntentId = result.data['paymentIntentId'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception('Invalid response from Stripe Cloud Function');
      }

      return PaymentIntentResult(
        success: true,
        transactionId: paymentIntentId,
        commissionAmount: commission,
        clientSecret: clientSecret,
        processedAt: now,
      );
    } catch (e) {
      return PaymentIntentResult(
        success: false,
        transactionId: txnId,
        errorMessage: 'Failed to create payment. Please try again.',
        processedAt: now,
      );
    }
  }

  @override
  Future<PaymentIntentResult> confirmPayment(String transactionId) async {
    final now = DateTime.now();
    try {
      final doc = await _firestore.collection('payment_intents').doc(transactionId).get();
      if (!doc.exists) {
        return PaymentIntentResult(
          success: false,
          transactionId: transactionId,
          errorMessage: 'Payment intent not found',
          processedAt: now,
        );
      }
      await _firestore.collection('payment_intents').doc(transactionId).update({
        'status': 'completed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      final data = doc.data()!;
      final orderId = data['orderId'] as String?;
      if (orderId != null) {
        await _firestore.collection('orders').doc(orderId).update({
          'paymentStatus': 'completed',
          'paidAt': now.toIso8601String(),
          'transactionId': transactionId,
        });
      }
      return PaymentIntentResult(
        success: true,
        transactionId: transactionId,
        commissionAmount: Money((data['commissionAmountInCents'] as num?)?.toInt() ?? 0),
        processedAt: now,
      );
    } catch (e) {
      return PaymentIntentResult(
        success: false,
        transactionId: transactionId,
        errorMessage: 'Payment confirmation failed. Please try again.',
        processedAt: now,
      );
    }
  }

  /// Create a wallet top-up PaymentIntent via Cloud Function.
  static Future<StripeTopUpResult> createTopUpIntent(int amountInCents) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createWalletTopUpIntent');
      final result = await callable.call({
        'amountInCents': amountInCents,
        'currency': 'usd',
      });
      return StripeTopUpResult(
        success: true,
        clientSecret: result.data['clientSecret'] as String,
        paymentIntentId: result.data['paymentIntentId'] as String,
      );
    } catch (e) {
      return StripeTopUpResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Confirm wallet top-up after Stripe succeeds.
  static Future<bool> confirmTopUp(String paymentIntentId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('confirmWalletTopUp');
      await callable.call({'paymentIntentId': paymentIntentId});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Transfer funds between user wallets.
  static Future<WalletTransferResult> transferFunds({
    required String recipientId,
    required double amountInDollars,
    String? note,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('transferWalletFunds');
      await callable.call({
        'recipientId': recipientId,
        'amountInDollars': amountInDollars,
        'note': note,
      });
      return WalletTransferResult(success: true);
    } catch (e) {
      return WalletTransferResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Request a driver payout via Cloud Function.
  static Future<DriverPayoutResult> requestDriverPayout({
    required int amountInCents,
    String? payoutMethod,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('processDriverPayout');
      final result = await callable.call({
        'amountInCents': amountInCents,
        'payoutMethod': payoutMethod ?? 'bank_transfer',
      });
      return DriverPayoutResult(
        success: true,
        payoutId: result.data['payoutId'] as String,
      );
    } catch (e) {
      return DriverPayoutResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

class StripeTopUpResult {
  final bool success;
  final String? clientSecret;
  final String? paymentIntentId;
  final String? errorMessage;
  const StripeTopUpResult({required this.success, this.clientSecret, this.paymentIntentId, this.errorMessage});
}

class WalletTransferResult {
  final bool success;
  final String? errorMessage;
  const WalletTransferResult({required this.success, this.errorMessage});
}

class DriverPayoutResult {
  final bool success;
  final String? payoutId;
  final String? errorMessage;
  const DriverPayoutResult({required this.success, this.payoutId, this.errorMessage});
}
