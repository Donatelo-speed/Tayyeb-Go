// Payment Helper - Simple payment methods
// Cash on Delivery always available
// Google/Apple Pay - shows as option but will indicate not available in demo

class PaymentHelper {
  static Future<bool> canMakeGooglePayPayment() async {
    return false; // Show but disabled for demo
  }

  static Future<bool> canMakeApplePayPayment() async {
    return false; // Show but disabled for demo
  }

  static Future<void> processGooglePay({
    required String totalAmount,
    required String orderLabel,
    required Function(String paymentToken) onSuccess,
    required Function(String) onError,
  }) async {
    onError('Google Pay: Contact admin to setup merchant account');
  }

  static Future<void> processApplePay({
    required String totalAmount,
    required String orderLabel,
    required Function(String paymentToken) onSuccess,
    required Function(String) onError,
  }) async {
    onError('Apple Pay: Contact admin to setup merchant account');
  }
}