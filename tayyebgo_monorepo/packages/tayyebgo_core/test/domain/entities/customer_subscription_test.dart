import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/entities/customer_subscription.dart';
import 'package:tayyebgo_core/domain/enums/subscription_plan.dart';
import 'package:tayyebgo_core/domain/enums/subscription_status.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';

void main() {
  group('CustomerSubscription', () {
    group('calculateDiscount', () {
      test('starter plan gives 3% discount', () {
        final sub = _makeSub(plan: SubscriptionPlanType.starter);
        final discount = sub.calculateDiscount(const Money(10000));
        // 3% of 10000 = 300
        expect(discount.amountInCents, 300);
      });

      test('plus plan gives 7% discount', () {
        final sub = _makeSub(plan: SubscriptionPlanType.plus);
        final discount = sub.calculateDiscount(const Money(10000));
        // 7% of 10000 = 700
        expect(discount.amountInCents, 700);
      });

      test('vip plan gives 15% discount', () {
        final sub = _makeSub(plan: SubscriptionPlanType.vip);
        final discount = sub.calculateDiscount(const Money(10000));
        // 15% of 10000 = 1500
        expect(discount.amountInCents, 1500);
      });

      test('returns 0 for inactive subscription', () {
        final sub = _makeSub(
          plan: SubscriptionPlanType.starter,
          status: SubscriptionStatus.expired,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        final discount = sub.calculateDiscount(const Money(10000));
        expect(discount.amountInCents, 0);
      });

      test('rounds to nearest cent', () {
        final sub = _makeSub(plan: SubscriptionPlanType.starter);
        final discount = sub.calculateDiscount(const Money(333));
        // 333 * 3 / 100 = 9.99 → rounds to 10
        expect(discount.amountInCents, 10);
      });
    });

    group('hasFreeDelivery', () {
      test('returns true for active subscription', () {
        final sub = _makeSub();
        expect(sub.hasFreeDelivery, isTrue);
      });

      test('returns false for inactive subscription', () {
        final sub = _makeSub(
          status: SubscriptionStatus.expired,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(sub.hasFreeDelivery, isFalse);
      });
    });

    group('isActive / isExpired', () {
      test('active when status is active and not past expiry', () {
        final sub = _makeSub();
        expect(sub.isActive, isTrue);
        expect(sub.isExpired, isFalse);
      });

      test('expired when past expiry date', () {
        final sub = _makeSub(
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(sub.isActive, isFalse);
        expect(sub.isExpired, isTrue);
      });

      test('not active when status is cancelled', () {
        final sub = _makeSub(status: SubscriptionStatus.cancelled);
        expect(sub.isActive, isFalse);
      });
    });

    group('daysRemaining', () {
      test('returns correct days for future date', () {
        final now = DateTime.now();
        final expiry = DateTime(now.year, now.month, now.day + 15, 23, 59, 59);
        final sub = _makeSub(expiryDate: expiry);
        expect(sub.daysRemaining, 15);
      });

      test('clamps to 0 for past date', () {
        final sub = _makeSub(
          expiryDate: DateTime.now().subtract(const Duration(days: 5)),
        );
        expect(sub.daysRemaining, 0);
      });
    });

    group('toMap / fromMap roundtrip', () {
      test('roundtrip preserves all fields', () {
        final original = _makeSub(
          id: 'test-id',
          userId: 'user-123',
          plan: SubscriptionPlanType.plus,
          status: SubscriptionStatus.active,
          totalSavings: 500.0,
          ordersUsed: 3,
          paymentTransactionId: 'txn-abc',
        );
        final map = original.toMap();
        final restored = CustomerSubscription.fromMap(map, original.id);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.plan, original.plan);
        expect(restored.status, original.status);
        expect(restored.pricePaid, original.pricePaid);
        expect(restored.totalSavings, original.totalSavings);
        expect(restored.ordersUsed, original.ordersUsed);
        expect(restored.paymentTransactionId, original.paymentTransactionId);
      });

      test('roundtrip with cancelled subscription', () {
        final original = _makeSub(
          status: SubscriptionStatus.cancelled,
          cancelledAt: DateTime(2025, 6, 1),
          cancelReason: 'Too expensive',
        );
        final map = original.toMap();
        final restored = CustomerSubscription.fromMap(map, original.id);

        expect(restored.status, SubscriptionStatus.cancelled);
        expect(restored.cancelledAt, DateTime(2025, 6, 1));
        expect(restored.cancelReason, 'Too expensive');
      });
    });

    group('copyWith', () {
      test('copies with updated status', () {
        final original = _makeSub();
        final updated = original.copyWith(status: SubscriptionStatus.cancelled);
        expect(updated.status, SubscriptionStatus.cancelled);
        expect(updated.plan, original.plan);
        expect(updated.userId, original.userId);
      });

      test('copies with updated ordersUsed', () {
        final original = _makeSub();
        final updated = original.copyWith(ordersUsed: 10);
        expect(updated.ordersUsed, 10);
      });
    });
  });

  group('SubscriptionPlanType', () {
    test('fromValue resolves known values', () {
      expect(SubscriptionPlanType.fromValue('starter'), SubscriptionPlanType.starter);
      expect(SubscriptionPlanType.fromValue('plus'), SubscriptionPlanType.plus);
      expect(SubscriptionPlanType.fromValue('pro'), SubscriptionPlanType.pro);
      expect(SubscriptionPlanType.fromValue('vip'), SubscriptionPlanType.vip);
    });

    test('fromValue defaults to starter for unknown', () {
      expect(SubscriptionPlanType.fromValue('unknown'), SubscriptionPlanType.starter);
    });

    test('discountPercent matches plan', () {
      expect(SubscriptionPlanType.starter.discountPercent, 3.0);
      expect(SubscriptionPlanType.plus.discountPercent, 7.0);
      expect(SubscriptionPlanType.pro.discountPercent, 12.0);
      expect(SubscriptionPlanType.vip.discountPercent, 15.0);
    });

    test('priceDisplay formats correctly', () {
      expect(SubscriptionPlanType.starter.priceDisplay, '\$5');
      expect(SubscriptionPlanType.plus.priceDisplay, '\$10');
      expect(SubscriptionPlanType.pro.priceDisplay, '\$20');
      expect(SubscriptionPlanType.vip.priceDisplay, '\$25');
    });
  });

  group('SubscriptionStatus', () {
    test('fromValue resolves known values', () {
      expect(SubscriptionStatus.fromValue('active'), SubscriptionStatus.active);
      expect(
          SubscriptionStatus.fromValue('expired'), SubscriptionStatus.expired);
      expect(SubscriptionStatus.fromValue('cancelled'),
          SubscriptionStatus.cancelled);
      expect(
          SubscriptionStatus.fromValue('pending'), SubscriptionStatus.pending);
    });

    test('fromValue defaults to pending for unknown', () {
      expect(SubscriptionStatus.fromValue('unknown'), SubscriptionStatus.pending);
    });

    test('isActive is true only for active', () {
      expect(SubscriptionStatus.active.isActive, isTrue);
      expect(SubscriptionStatus.expired.isActive, isFalse);
    });

    test('canBeRenewable is true for expired and cancelled', () {
      expect(SubscriptionStatus.expired.canBeRenewable, isTrue);
      expect(SubscriptionStatus.cancelled.canBeRenewable, isTrue);
      expect(SubscriptionStatus.active.canBeRenewable, isFalse);
    });
  });
}

CustomerSubscription _makeSub({
  String id = 'sub-1',
  String userId = 'user-1',
  SubscriptionPlanType plan = SubscriptionPlanType.starter,
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? expiryDate,
  double totalSavings = 0,
  int ordersUsed = 0,
  String? paymentTransactionId,
  DateTime? cancelledAt,
  String? cancelReason,
}) {
  final now = DateTime.now();
  return CustomerSubscription(
    id: id,
    userId: userId,
    plan: plan,
    status: status,
    startDate: now,
    expiryDate: expiryDate ?? now.add(const Duration(days: 30)),
    pricePaid: Money(plan.priceInCents),
    paymentTransactionId: paymentTransactionId,
    totalSavings: totalSavings,
    ordersUsed: ordersUsed,
    createdAt: now,
    cancelledAt: cancelledAt,
    cancelReason: cancelReason,
  );
}
