// Web stub — no flutter_stripe import, no Platform access.
// This file is used on web via conditional import.

class StripeWrapper {
  Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {
    // No-op on web
  }

  Future<void> presentPaymentSheet() async {
    // No-op on web
  }
}

StripeWrapper createStripeWrapper() => StripeWrapper();
