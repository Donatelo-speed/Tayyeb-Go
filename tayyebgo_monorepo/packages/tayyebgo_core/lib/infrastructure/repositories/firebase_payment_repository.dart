import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/i_payment_repository.dart';

class FirebasePaymentRepository implements IPaymentRepository {
  static final FirebasePaymentRepository instance = FirebasePaymentRepository._();
  FirebasePaymentRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseFunctions get _functions => FirebaseFunctions.instance;
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
    try {
      final callable = _functions.httpsCallable('createStripePaymentIntent');
      final result = await callable.call({
        'amountInCents': amountInCents,
        'currency': currency,
        'orderId': orderId,
        'metadata': {
          'paymentMethodId': paymentMethodId,
        },
      });

      final clientSecret = result.data['clientSecret'] as String?;
      final paymentIntentId = result.data['paymentIntentId'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception('Invalid response from payment service');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': 'processing',
        'stripePaymentIntentId': paymentIntentId,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'clientSecret': clientSecret,
        'transactionId': paymentIntentId,
        'amount': amountInCents,
        'currency': currency,
      };
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Payment processing failed');
    } catch (e) {
      throw Exception('Payment processing failed. Please try again.');
    }
  }
}
