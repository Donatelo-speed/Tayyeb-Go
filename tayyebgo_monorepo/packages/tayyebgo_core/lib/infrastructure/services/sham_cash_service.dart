import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/services/i_payment_service.dart';
import '../../domain/value_objects/money.dart';
import 'commission_calculator.dart';

class ShamCashService implements IPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CommissionCalculator _commission = CommissionCalculator();

  @override
  Future<PaymentIntentResult> createPaymentIntent(PaymentIntentRequest request) async {
    final now = DateTime.now();
    final txnId = 'sham_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final commission = _commission.calculate(request.amount, request.commissionPercent);

    try {
      await _firestore.collection('payment_intents').doc(txnId).set({
        'orderId': request.orderId,
        'amountInCents': request.amount.amountInCents,
        'currency': request.currency,
        'method': 'sham_cash',
        'status': 'pending',
        'commissionAmountInCents': commission.amountInCents,
        'commissionPercent': request.commissionPercent,
        'restaurantId': request.restaurantId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('Orders').doc(request.orderId).update({
        'paymentMethodType': 'sham_cash',
        'paymentStatus': 'pending',
        'transactionId': txnId,
        'commissionAmountInCents': commission.amountInCents,
      });

      return PaymentIntentResult(
        success: true,
        transactionId: txnId,
        commissionAmount: commission,
        processedAt: now,
      );
    } catch (e) {
      return PaymentIntentResult(
        success: false,
        transactionId: txnId,
        errorMessage: 'Failed to create payment record. Please try again.',
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
      final data = doc.data()!;
      await _firestore.collection('payment_intents').doc(transactionId).update({
        'status': 'completed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('Orders').doc(data['orderId'] as String?).update({
        'paymentStatus': 'completed',
        'paidAt': now.toIso8601String(),
      });
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
}
