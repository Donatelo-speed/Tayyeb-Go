import '../../domain/services/i_payment_provider.dart';
import '../../domain/enums/payment_method_type.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/services/i_payment_service.dart';
import 'stripe_checkout_service.dart';

class StripePaymentProvider implements IPaymentProvider {
  final StripeCheckoutService _service;

  StripePaymentProvider({StripeCheckoutService? service})
      : _service = service ?? StripeCheckoutService();

  @override
  PaymentMethodType get methodType => PaymentMethodType.stripe;

  @override
  Future<PaymentProviderResult> createPayment({
    required String orderId,
    required Money amount,
    required String currency,
    required String userId,
    double commissionPercent = 15.0,
  }) async {
    try {
      final request = PaymentIntentRequest(
        orderId: orderId,
        amount: amount,
        currency: currency,
        method: PaymentMethodType.stripe,
        commissionPercent: commissionPercent,
      );
      final result = await _service.createPaymentIntent(request);
      if (result.success) {
        return PaymentProviderResult(
          success: true,
          transactionId: result.transactionId,
          clientSecret: result.clientSecret,
        );
      }
      return PaymentProviderResult.failure(
        result.errorMessage ?? 'Failed to create Stripe payment intent',
      );
    } catch (e) {
      return PaymentProviderResult.failure(e.toString());
    }
  }

  @override
  Future<PaymentProviderResult> confirmPayment({
    required String transactionId,
    required String orderId,
  }) async {
    try {
      final result = await _service.confirmPayment(transactionId);
      if (result.success) {
        return PaymentProviderResult.success(transactionId: transactionId);
      }
      return PaymentProviderResult.failure(
        result.errorMessage ?? 'Stripe confirmation failed',
      );
    } catch (e) {
      return PaymentProviderResult.failure(e.toString());
    }
  }

  @override
  Future<PaymentProviderResult> refund({
    required String transactionId,
    required Money amount,
    String? reason,
  }) async =>
      PaymentProviderResult.failure('Stripe refunds not implemented');

  @override
  Future<bool> isAvailable() async => true;
}
