import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/enums/payment_method_type.dart';
import 'package:tayyebgo_core/domain/services/i_payment_provider.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';

void main() {
  group('PaymentProviderResult', () {
    test('success factory creates successful result', () {
      final result = PaymentProviderResult.success(transactionId: 'txn_1');
      expect(result.success, isTrue);
      expect(result.transactionId, 'txn_1');
      expect(result.errorMessage, isNull);
    });

    test('success factory without transactionId', () {
      final result = PaymentProviderResult.success();
      expect(result.success, isTrue);
      expect(result.transactionId, isNull);
    });

    test('failure factory creates failed result', () {
      final result = PaymentProviderResult.failure('Something went wrong');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Something went wrong');
      expect(result.transactionId, isNull);
    });

    test('constructor with all fields', () {
      final result = PaymentProviderResult(
        success: true,
        transactionId: 'txn_1',
        clientSecret: 'cs_secret',
        checkoutUrl: 'https://checkout.stripe.com',
      );
      expect(result.success, isTrue);
      expect(result.transactionId, 'txn_1');
      expect(result.clientSecret, 'cs_secret');
      expect(result.checkoutUrl, 'https://checkout.stripe.com');
    });
  });

  group('CashPaymentProvider', () {
    test('methodType is cashOnDelivery', () {
      // We test the property value without instantiating Firestore-dependent provider
      expect(PaymentMethodType.cashOnDelivery.value, 'cash');
      expect(PaymentMethodType.cashOnDelivery.displayName, 'Cash on Delivery');
    });
  });

  group('ShamCashPaymentProvider', () {
    test('methodType is shamCash', () {
      expect(PaymentMethodType.shamCash.value, 'sham_cash');
      expect(PaymentMethodType.shamCash.displayName, 'Sham Cash');
    });
  });

  group('StripePaymentProvider', () {
    test('methodType is stripe', () {
      expect(PaymentMethodType.stripe.value, 'stripe');
      expect(PaymentMethodType.stripe.displayName, 'Visa / Mastercard');
    });
  });

  group('PaymentMethodType', () {
    test('fromValue returns correct type', () {
      expect(PaymentMethodType.fromValue('cash'), PaymentMethodType.cashOnDelivery);
      expect(PaymentMethodType.fromValue('sham_cash'), PaymentMethodType.shamCash);
      expect(PaymentMethodType.fromValue('stripe'), PaymentMethodType.stripe);
    });

    test('fromValue defaults to cashOnDelivery for unknown', () {
      expect(PaymentMethodType.fromValue('unknown'), PaymentMethodType.cashOnDelivery);
    });
  });

  group('Money for payment tests', () {
    test('amountInCents is correct', () {
      const money = Money(5000);
      expect(money.amountInCents, 5000);
      expect(money.inDollars, 50.0);
    });

    test('fromDollars creates correct Money', () {
      final money = Money.fromDollars(25.50);
      expect(money.amountInCents, 2550);
    });
  });
}
