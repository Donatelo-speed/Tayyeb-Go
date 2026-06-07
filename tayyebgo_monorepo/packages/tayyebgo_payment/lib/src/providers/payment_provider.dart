import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment.dart';

class PaymentProvider {
  final FirebaseFirestore _firestore;

  PaymentProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Payment> processPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
  }) async {
    final paymentRef = _firestore.collection('payments').doc();

    final payment = Payment(
      id: paymentRef.id,
      orderId: orderId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );

    await paymentRef.set(payment.toJson());

    return payment;
  }

  Stream<Payment?> watchPayment(String orderId) {
    return _firestore
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return Payment.fromJson(snap.docs.first.data());
    });
  }

  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };
    if (transactionId != null) {
      updates['transactionId'] = transactionId;
    }
    await _firestore.collection('payments').doc(paymentId).update(updates);
  }
}
