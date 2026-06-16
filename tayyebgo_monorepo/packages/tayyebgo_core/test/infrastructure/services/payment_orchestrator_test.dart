import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/enums/payment_method_type.dart';
import 'package:tayyebgo_core/domain/services/i_payment_provider.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';
import 'package:tayyebgo_core/infrastructure/services/payment_orchestrator.dart';

class MockPaymentProvider implements IPaymentProvider {
  @override
  final PaymentMethodType methodType;

  final PaymentProviderResult _createResult;
  final PaymentProviderResult _confirmResult;
  final bool _isAvailable;

  MockPaymentProvider({
    required this.methodType,
    PaymentProviderResult? createResult,
    PaymentProviderResult? confirmResult,
    bool isAvailable = true,
  })  : _createResult =
            createResult ?? PaymentProviderResult.success(transactionId: 'mock_txn'),
        _confirmResult =
            confirmResult ?? PaymentProviderResult.success(transactionId: 'mock_txn'),
        _isAvailable = isAvailable;

  @override
  Future<PaymentProviderResult> createPayment({
    required String orderId,
    required Money amount,
    required String currency,
    required String userId,
    double commissionPercent = 15.0,
  }) async =>
      _createResult;

  @override
  Future<PaymentProviderResult> confirmPayment({
    required String transactionId,
    required String orderId,
  }) async =>
      _confirmResult;

  @override
  Future<PaymentProviderResult> refund({
    required String transactionId,
    required Money amount,
    String? reason,
  }) async =>
      PaymentProviderResult.failure('Not implemented');

  @override
  Future<bool> isAvailable() async => _isAvailable;
}

void main() {
  late PaymentOrchestrator orchestrator;

  setUp(() {
    orchestrator = PaymentOrchestrator.createTestInstance();
  });

  group('PaymentOrchestrator.register', () {
    test('registers a provider', () {
      final provider = MockPaymentProvider(methodType: PaymentMethodType.cashOnDelivery);
      orchestrator.register(provider);

      expect(orchestrator.getProvider(PaymentMethodType.cashOnDelivery), provider);
    });

    test('registers multiple providers', () {
      orchestrator.register(MockPaymentProvider(methodType: PaymentMethodType.cashOnDelivery));
      orchestrator.register(MockPaymentProvider(methodType: PaymentMethodType.shamCash));
      orchestrator.register(MockPaymentProvider(methodType: PaymentMethodType.stripe));

      expect(orchestrator.registeredTypes, contains(PaymentMethodType.cashOnDelivery));
      expect(orchestrator.registeredTypes, contains(PaymentMethodType.shamCash));
      expect(orchestrator.registeredTypes, contains(PaymentMethodType.stripe));
      expect(orchestrator.registeredTypes.length, 3);
    });

    test('overwrites provider of same type', () {
      final p1 = MockPaymentProvider(methodType: PaymentMethodType.stripe);
      final p2 = MockPaymentProvider(methodType: PaymentMethodType.stripe);
      orchestrator.register(p1);
      orchestrator.register(p2);

      expect(orchestrator.getProvider(PaymentMethodType.stripe), p2);
    });
  });

  group('PaymentOrchestrator.getProvider', () {
    test('returns null for unregistered type', () {
      expect(orchestrator.getProvider(PaymentMethodType.stripe), isNull);
    });
  });

  group('PaymentOrchestrator.pay', () {
    test('routes to correct provider', () async {
      final provider = MockPaymentProvider(methodType: PaymentMethodType.cashOnDelivery);
      orchestrator.register(provider);

      final result = await orchestrator.pay(
        method: PaymentMethodType.cashOnDelivery,
        orderId: 'order_1',
        amount: const Money(5000),
        currency: 'usd',
        userId: 'user_1',
      );

      expect(result.success, isTrue);
      expect(result.transactionId, 'mock_txn');
    });

    test('returns failure for unregistered method', () async {
      final result = await orchestrator.pay(
        method: PaymentMethodType.stripe,
        orderId: 'order_1',
        amount: const Money(5000),
        currency: 'usd',
        userId: 'user_1',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('not available'));
    });

    test('returns failure when provider is not available', () async {
      orchestrator.register(
        MockPaymentProvider(
          methodType: PaymentMethodType.shamCash,
          isAvailable: false,
        ),
      );

      final result = await orchestrator.pay(
        method: PaymentMethodType.shamCash,
        orderId: 'order_1',
        amount: const Money(5000),
        currency: 'usd',
        userId: 'user_1',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('not available'));
    });

    test('returns provider failure result', () async {
      orchestrator.register(
        MockPaymentProvider(
          methodType: PaymentMethodType.stripe,
          createResult: PaymentProviderResult.failure('Stripe error'),
        ),
      );

      final result = await orchestrator.pay(
        method: PaymentMethodType.stripe,
        orderId: 'order_1',
        amount: const Money(5000),
        currency: 'usd',
        userId: 'user_1',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Stripe error');
    });
  });

  group('PaymentOrchestrator.confirm', () {
    test('routes confirmation to correct provider', () async {
      orchestrator.register(
        MockPaymentProvider(
          methodType: PaymentMethodType.shamCash,
          confirmResult: PaymentProviderResult.success(transactionId: 'txn_123'),
        ),
      );

      final result = await orchestrator.confirm(
        method: PaymentMethodType.shamCash,
        transactionId: 'txn_123',
        orderId: 'order_1',
      );

      expect(result.success, isTrue);
      expect(result.transactionId, 'txn_123');
    });

    test('returns failure for unregistered method', () async {
      final result = await orchestrator.confirm(
        method: PaymentMethodType.stripe,
        transactionId: 'txn_123',
        orderId: 'order_1',
      );

      expect(result.success, isFalse);
    });
  });
}
