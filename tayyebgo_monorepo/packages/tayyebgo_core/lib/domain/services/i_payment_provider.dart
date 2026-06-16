import '../enums/payment_method_type.dart';
import '../value_objects/money.dart';

/// Result of a payment operation
class PaymentProviderResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final String? clientSecret; // For Stripe frontend confirmation
  final String? checkoutUrl;

  const PaymentProviderResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.clientSecret,
    this.checkoutUrl,
  });

  factory PaymentProviderResult.success({String? transactionId}) =>
      PaymentProviderResult(success: true, transactionId: transactionId);

  factory PaymentProviderResult.failure(String message) =>
      PaymentProviderResult(success: false, errorMessage: message);
}

/// Abstract interface for payment providers.
/// Each payment method (Cash, ShamCash, Stripe) implements this.
abstract class IPaymentProvider {
  PaymentMethodType get methodType;

  /// Create a payment intent/record
  Future<PaymentProviderResult> createPayment({
    required String orderId,
    required Money amount,
    required String currency,
    required String userId,
    double commissionPercent = 15.0,
  });

  /// Confirm/capture a payment
  Future<PaymentProviderResult> confirmPayment({
    required String transactionId,
    required String orderId,
  });

  /// Refund a payment
  Future<PaymentProviderResult> refund({
    required String transactionId,
    required Money amount,
    String? reason,
  });

  /// Whether this provider is available for the current user/region
  Future<bool> isAvailable();
}
