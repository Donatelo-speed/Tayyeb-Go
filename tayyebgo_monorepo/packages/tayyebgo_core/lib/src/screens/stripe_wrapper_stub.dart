// Web stub for Stripe — no-op, no flutter_stripe import.

class CoreStripeWrapper {
  Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {}

  Future<void> presentPaymentSheet() async {}
}

CoreStripeWrapper createCoreStripeWrapper() => CoreStripeWrapper();
