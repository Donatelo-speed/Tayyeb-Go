import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/i_payment_repository.dart';

class FirebasePaymentRepository implements IPaymentRepository {
  static final FirebasePaymentRepository instance = FirebasePaymentRepository._();
  FirebasePaymentRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('payment_methods');

  @override
  Stream<List<PaymentMethod>> watchByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs
          .map((d) =>
              PaymentMethod.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Future<void> save(PaymentMethod method) =>
      _col.doc(method.id).set(method.toMap());

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  @override
  Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required int amountInCents,
    required String currency,
    required String paymentMethodId,
  }) async {
    // Stripe integration placeholder — returns a mock success
    await _firestore.collection('orders').doc(orderId).update({
      'paymentStatus': 'completed',
      'paidAt': DateTime.now().toIso8601String(),
    });
    return {
      'success': true,
      'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amountInCents,
      'currency': currency,
    };
  }
}
