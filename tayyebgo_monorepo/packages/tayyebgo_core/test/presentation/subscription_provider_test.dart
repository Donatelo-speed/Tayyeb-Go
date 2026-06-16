import 'package:flutter_test/flutter_test.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

void main() {
  group('SubscriptionPlanType', () {
    test('starter has correct properties', () {
      const plan = SubscriptionPlanType.starter;
      expect(plan.value, 'starter');
      expect(plan.displayName, 'Starter');
      expect(plan.durationMonths, 1);
      expect(plan.priceInCents, 500);
      expect(plan.discountPercent, 3.0);
      expect(plan.priceDisplay, '\$5');
      expect(plan.benefits, contains('free_delivery_first_3_orders'));
      expect(plan.benefits, contains('3_percent_discount'));
    });

    test('plus has correct properties', () {
      const plan = SubscriptionPlanType.plus;
      expect(plan.value, 'plus');
      expect(plan.displayName, 'Plus');
      expect(plan.durationMonths, 3);
      expect(plan.priceInCents, 1000);
      expect(plan.discountPercent, 7.0);
      expect(plan.priceDisplay, '\$10');
      expect(plan.benefits, contains('7_percent_discount'));
      expect(plan.benefits, contains('priority_support'));
    });

    test('pro has correct properties', () {
      const plan = SubscriptionPlanType.pro;
      expect(plan.value, 'pro');
      expect(plan.displayName, 'Pro');
      expect(plan.durationMonths, 6);
      expect(plan.priceInCents, 2000);
      expect(plan.discountPercent, 12.0);
      expect(plan.priceDisplay, '\$20');
      expect(plan.benefits, contains('exclusive_deals'));
      expect(plan.benefits, contains('early_access'));
    });

    test('vip has correct properties', () {
      const plan = SubscriptionPlanType.vip;
      expect(plan.value, 'vip');
      expect(plan.displayName, 'VIP');
      expect(plan.durationMonths, 12);
      expect(plan.priceInCents, 2500);
      expect(plan.discountPercent, 15.0);
      expect(plan.priceDisplay, '\$25');
      expect(plan.benefits, contains('dedicated_support'));
      expect(plan.benefits, contains('monthly_free_item'));
    });

    test('fromValue returns correct plan', () {
      expect(SubscriptionPlanType.fromValue('starter'), SubscriptionPlanType.starter);
      expect(SubscriptionPlanType.fromValue('plus'), SubscriptionPlanType.plus);
      expect(SubscriptionPlanType.fromValue('pro'), SubscriptionPlanType.pro);
      expect(SubscriptionPlanType.fromValue('vip'), SubscriptionPlanType.vip);
    });

    test('fromValue defaults to starter for unknown value', () {
      expect(SubscriptionPlanType.fromValue('unknown'), SubscriptionPlanType.starter);
    });
  });

  group('SubscriptionStatus', () {
    test('isActive returns true only for active status', () {
      expect(SubscriptionStatus.active.isActive, isTrue);
      expect(SubscriptionStatus.expired.isActive, isFalse);
      expect(SubscriptionStatus.cancelled.isActive, isFalse);
      expect(SubscriptionStatus.pending.isActive, isFalse);
    });

    test('canBeRenewable returns true for expired or cancelled', () {
      expect(SubscriptionStatus.expired.canBeRenewable, isTrue);
      expect(SubscriptionStatus.cancelled.canBeRenewable, isTrue);
      expect(SubscriptionStatus.active.canBeRenewable, isFalse);
      expect(SubscriptionStatus.pending.canBeRenewable, isFalse);
    });

    test('fromValue returns correct status', () {
      expect(SubscriptionStatus.fromValue('active'), SubscriptionStatus.active);
      expect(SubscriptionStatus.fromValue('expired'), SubscriptionStatus.expired);
      expect(SubscriptionStatus.fromValue('cancelled'), SubscriptionStatus.cancelled);
      expect(SubscriptionStatus.fromValue('pending'), SubscriptionStatus.pending);
    });

    test('fromValue defaults to pending for unknown value', () {
      expect(SubscriptionStatus.fromValue('unknown'), SubscriptionStatus.pending);
    });
  });

  group('CustomerSubscription', () {
    test('isActive returns true when status is active and not expired', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now(),
      );
      expect(sub.isActive, isTrue);
      expect(sub.isExpired, isFalse);
    });

    test('isActive returns false when expired', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 100)),
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      );
      expect(sub.isActive, isFalse);
      expect(sub.isExpired, isTrue);
    });

    test('isActive returns false when status is cancelled', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.cancelled,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now(),
      );
      expect(sub.isActive, isFalse);
    });

    test('calculateDiscount returns correct amount for plus plan', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now(),
      );
      final discount = sub.calculateDiscount(const Money(10000));
      // 7% of 10000 = 700
      expect(discount.amountInCents, 700);
    });

    test('calculateDiscount returns zero when inactive', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.cancelled,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now(),
      );
      final discount = sub.calculateDiscount(const Money(10000));
      expect(discount.amountInCents, 0);
    });

    test('daysRemaining returns correct count', () {
      final now = DateTime.now();
      final expiry = DateTime(now.year, now.month, now.day + 15, 23, 59, 59);
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: now,
        expiryDate: expiry,
        pricePaid: const Money(1000),
        createdAt: now,
      );
      expect(sub.daysRemaining, 15);
    });

    test('daysRemaining clamps to 0 for expired', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 100)),
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      );
      expect(sub.daysRemaining, 0);
    });

    test('hasFreeDelivery returns true when active', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.starter,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        pricePaid: const Money(500),
        createdAt: DateTime.now(),
      );
      expect(sub.hasFreeDelivery, isTrue);
    });

    test('hasFreeDelivery returns false when inactive', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.starter,
        status: SubscriptionStatus.cancelled,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        pricePaid: const Money(500),
        createdAt: DateTime.now(),
      );
      expect(sub.hasFreeDelivery, isFalse);
    });

    test('toMap and fromMap are round-trip compatible', () {
      final now = DateTime.now();
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: now,
        expiryDate: now.add(const Duration(days: 90)),
        pricePaid: const Money(1000),
        paymentTransactionId: 'txn-123',
        totalSavings: 42.50,
        ordersUsed: 7,
        createdAt: now,
      );
      final map = sub.toMap();
      final restored = CustomerSubscription.fromMap(map, 'test-id');
      expect(restored.id, 'test-id');
      expect(restored.userId, 'user-1');
      expect(restored.plan, SubscriptionPlanType.plus);
      expect(restored.status, SubscriptionStatus.active);
      expect(restored.pricePaid.amountInCents, 1000);
      expect(restored.paymentTransactionId, 'txn-123');
      expect(restored.totalSavings, 42.50);
      expect(restored.ordersUsed, 7);
    });

    test('copyWith creates a copy with overridden fields', () {
      final sub = CustomerSubscription(
        id: 'test-id',
        userId: 'user-1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now(),
      );
      final cancelled = sub.copyWith(
        status: SubscriptionStatus.cancelled,
        cancelReason: 'Too expensive',
      );
      expect(cancelled.id, sub.id);
      expect(cancelled.status, SubscriptionStatus.cancelled);
      expect(cancelled.cancelReason, 'Too expensive');
      expect(cancelled.plan, SubscriptionPlanType.plus);
    });
  });

  group('Money', () {
    test('format returns correct string', () {
      const money = Money(500);
      expect(money.format(), '\$5.00');
    });

    test('inDollars returns correct value', () {
      const money = Money(1234);
      expect(money.inDollars, closeTo(12.34, 0.001));
    });

    test('arithmetic operations work correctly', () {
      const a = Money(1000);
      const b = Money(500);
      expect((a + b).amountInCents, 1500);
      expect((a - b).amountInCents, 500);
      expect((a * 2).amountInCents, 2000);
    });

    test('equality works', () {
      const a = Money(1000);
      const b = Money(1000);
      const c = Money(2000);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
    });
  });
}
