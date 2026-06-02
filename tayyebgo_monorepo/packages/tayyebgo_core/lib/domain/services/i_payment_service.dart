import '../enums/payment_method_type.dart';
import '../value_objects/money.dart';

class PaymentIntentRequest {
  final String orderId;
  final Money amount;
  final String currency;
  final PaymentMethodType method;
  final String? restaurantId;
  final double commissionPercent;

  const PaymentIntentRequest({
    required this.orderId,
    required this.amount,
    this.currency = 'usd',
    required this.method,
    this.restaurantId,
    this.commissionPercent = 15.0,
  });
}

class PaymentIntentResult {
  final bool success;
  final String transactionId;
  final Money? commissionAmount;
  final String? checkoutUrl;
  final String? errorMessage;
  final DateTime processedAt;

  const PaymentIntentResult({
    required this.success,
    required this.transactionId,
    this.commissionAmount,
    this.checkoutUrl,
    this.errorMessage,
    required this.processedAt,
  });
}

abstract class IPaymentService {
  Future<PaymentIntentResult> createPaymentIntent(PaymentIntentRequest request);
  Future<PaymentIntentResult> confirmPayment(String transactionId);
}
