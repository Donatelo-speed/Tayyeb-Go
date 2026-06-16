import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/entities/customer_subscription.dart';
import 'package:tayyebgo_core/domain/enums/subscription_plan.dart';
import 'package:tayyebgo_core/domain/enums/subscription_status.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';

void main() {
  group('CustomerSubscription', () {
    group('calculateDiscount', () {
      test('basic plan gives 5% discount', () {
        final sub = _makeSub(plan: SubscriptionPlanType.basic);
        final discount = sub.calculateDiscount(const Money(10000));
        expect(discount.amountInCents, 500);
      });

      test('plus plan gives 10% discount', () {
        final sub = _makeSub(plan: SubscriptionPlanType.plus);
        final discount = sub.calculateDiscount(const Money(10000));
        expect(discount.amountInCents, 1000);
      });

      test('premium plan gives 15% discount', () {
        final sub = _makeSub(plan: SubscriptionPlanType.premium);
        final discount = sub.calculateDiscount(const Money(10000));
        expect(discount.amountInCents, 1500);
      });

      test('returns 0 for inactive subscription', () {
        final sub = _makeSub(
          plan: SubscriptionPlanType.basic,
          status: SubscriptionStatus.expired,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        final discount = sub.calculateDiscount(const Money(10000));
        expect(discount.amountInCents, 0);
      });

      test('rounds to nearest cent', () {
        final sub = _makeSub(plan: SubscriptionPlanType.basic);
        final discount = sub.calculateDiscount(const Money(333));
        // 333 * 5 / 100 = 16.65 → rounds to 17
        expect(discount.amountInCents, 17);
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
        final expiry = DateTime.now().add(const Duration(days: 15));
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
      expect(SubscriptionPlanType.fromValue('basic'), SubscriptionPlanType.basic);
      expect(SubscriptionPlanType.fromValue('plus'), SubscriptionPlanType.plus);
      expect(
          SubscriptionPlanType.fromValue('premium'), SubscriptionPlanType.premium);
    });

    test('fromValue defaults to basic for unknown', () {
      expect(SubscriptionPlanType.fromValue('unknown'), SubscriptionPlanType.basic);
    });

    test('discountPercent matches plan', () {
      expect(SubscriptionPlanType.basic.discountPercent, 5.0);
      expect(SubscriptionPlanType.plus.discountPercent, 10.0);
      expect(SubscriptionPlanType.premium.discountPercent, 15.0);
    });

    test('priceDisplay formats correctly', () {
      expect(SubscriptionPlanType.basic.priceDisplay, '\$100');
      expect(SubscriptionPlanType.plus.priceDisplay, '\$250');
      expect(SubscriptionPlanType.premium.priceDisplay, '\$450');
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
  SubscriptionPlanType plan = SubscriptionPlanType.basic,
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
