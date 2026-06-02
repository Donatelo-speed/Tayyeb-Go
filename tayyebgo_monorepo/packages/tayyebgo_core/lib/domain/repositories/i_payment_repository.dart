import '../entities/payment_method.dart';

abstract class IPaymentRepository {
  Stream<List<PaymentMethod>> watchByUser(String userId);
  Future<void> save(PaymentMethod method);
  Future<void> delete(String id);
  Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required int amountInCents,
    required String currency,
    required String paymentMethodId,
  });
}
