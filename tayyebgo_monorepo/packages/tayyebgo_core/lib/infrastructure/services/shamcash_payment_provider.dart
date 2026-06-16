import '../../domain/services/i_payment_provider.dart';
import '../../domain/enums/payment_method_type.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/services/i_payment_service.dart';
import 'sham_cash_service.dart';

class ShamCashPaymentProvider implements IPaymentProvider {
  final ShamCashService _service;

  ShamCashPaymentProvider({ShamCashService? service})
      : _service = service ?? ShamCashService();

  @override
  PaymentMethodType get methodType => PaymentMethodType.shamCash;

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
        method: PaymentMethodType.shamCash,
        commissionPercent: commissionPercent,
      );
      final result = await _service.createPaymentIntent(request);
      if (result.success) {
        return PaymentProviderResult.success(
          transactionId: result.transactionId,
        );
      }
      return PaymentProviderResult.failure(
        result.errorMessage ?? 'Failed to create ShamCash payment',
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
        result.errorMessage ?? 'ShamCash confirmation failed',
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
      PaymentProviderResult.failure('ShamCash refunds not supported');

  @override
  Future<bool> isAvailable() async => true;
}
