import '../../domain/services/i_payment_provider.dart';
import '../../domain/enums/payment_method_type.dart';
import '../../domain/value_objects/money.dart';

/// Orchestrates payments by routing to the correct provider.
/// The app should use this instead of calling providers directly.
class PaymentOrchestrator {
  static final PaymentOrchestrator instance = PaymentOrchestrator._();
  PaymentOrchestrator._();

  /// Create a fresh instance for testing.
  static PaymentOrchestrator createTestInstance() => PaymentOrchestrator._();

  final Map<PaymentMethodType, IPaymentProvider> _providers = {};

  /// Register a payment provider. Can be called multiple times for different types.
  void register(IPaymentProvider provider) {
    _providers[provider.methodType] = provider;
  }

  /// Get a specific provider by type.
  IPaymentProvider? getProvider(PaymentMethodType type) => _providers[type];

  /// All registered provider types.
  Iterable<PaymentMethodType> get registeredTypes => _providers.keys;

  /// Create a payment through the appropriate provider.
  Future<PaymentProviderResult> pay({
    required PaymentMethodType method,
    required String orderId,
    required Money amount,
    required String currency,
    required String userId,
    double commissionPercent = 15.0,
  }) async {
    final provider = _providers[method];
    if (provider == null) {
      return PaymentProviderResult.failure(
        'Payment method not available: ${method.displayName}',
      );
    }
    if (!await provider.isAvailable()) {
      return PaymentProviderResult.failure(
        '${method.displayName} is not available',
      );
    }
    return provider.createPayment(
      orderId: orderId,
      amount: amount,
      currency: currency,
      userId: userId,
      commissionPercent: commissionPercent,
    );
  }

  /// Confirm a payment through the appropriate provider.
  Future<PaymentProviderResult> confirm({
    required PaymentMethodType method,
    required String transactionId,
    required String orderId,
  }) async {
    final provider = _providers[method];
    if (provider == null) {
      return PaymentProviderResult.failure('Payment method not available');
    }
    return provider.confirmPayment(
      transactionId: transactionId,
      orderId: orderId,
    );
  }
}
