import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/services/i_payment_provider.dart';
import '../../domain/enums/payment_method_type.dart';
import '../../domain/value_objects/money.dart';

class CashPaymentProvider implements IPaymentProvider {
  @override
  PaymentMethodType get methodType => PaymentMethodType.cashOnDelivery;

  @override
  Future<PaymentProviderResult> createPayment({
    required String orderId,
    required Money amount,
    required String currency,
    required String userId,
    double commissionPercent = 15.0,
  }) async {
    final docRef = await FirebaseFirestore.instance.collection('payments').add({
      'orderId': orderId,
      'userId': userId,
      'amount': amount.amountInCents,
      'currency': currency,
      'method': 'cash',
      'status': 'pending',
      'commissionPercent': commissionPercent,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return PaymentProviderResult.success(transactionId: docRef.id);
  }

  @override
  Future<PaymentProviderResult> confirmPayment({
    required String transactionId,
    required String orderId,
  }) async {
    await FirebaseFirestore.instance
        .collection('payments')
        .doc(transactionId)
        .update({
      'status': 'completed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });
    return PaymentProviderResult.success(transactionId: transactionId);
  }

  @override
  Future<PaymentProviderResult> refund({
    required String transactionId,
    required Money amount,
    String? reason,
  }) async =>
      PaymentProviderResult.failure('Cash payments cannot be refunded electronically');

  @override
  Future<bool> isAvailable() async => true;
}
