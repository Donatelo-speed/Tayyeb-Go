abstract class PaymentGateway {
  Future<PaymentResult> charge(ChargeRequest request);
  Future<PaymentResult> refund(RefundRequest request);
}

class ChargeRequest {
  final String orderId;
  final int amountInCents;
  final String currency;
  final String paymentMethodId;
  final String? description;

  const ChargeRequest({
    required this.orderId,
    required this.amountInCents,
    required this.currency,
    required this.paymentMethodId,
    this.description,
  });
}

class RefundRequest {
  final String transactionId;
  final int amountInCents;

  const RefundRequest({
    required this.transactionId,
    required this.amountInCents,
  });
}

class PaymentResult {
  final bool success;
  final String transactionId;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.transactionId,
    this.errorMessage,
  });
}

class StripePaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> charge(ChargeRequest request) async {
    // Integrate with Stripe.js on web
    return PaymentResult(
      success: true,
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<PaymentResult> refund(RefundRequest request) async {
    return PaymentResult(
      success: true,
      transactionId: request.transactionId,
    );
  }
}
