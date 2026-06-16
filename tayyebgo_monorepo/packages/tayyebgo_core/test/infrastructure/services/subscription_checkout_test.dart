import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/entities/customer_subscription.dart';
import 'package:tayyebgo_core/domain/enums/subscription_plan.dart';
import 'package:tayyebgo_core/domain/enums/subscription_status.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';
import 'package:tayyebgo_core/infrastructure/services/subscription_service.dart';

void main() {
  group('SubscriptionService.applyBenefits', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService.instance;
    });

    test('applies 7% discount for active Plus subscription', () {
      final subscription = CustomerSubscription(
        id: 'sub_1',
        userId: 'user_1',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 60)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(10000),
        isDelivery: true,
      );

      // 7% of 10000 = 700
      expect(result.discount, const Money(700));
      expect(result.freeDelivery, true);
    });

    test('applies 3% discount for active Starter subscription', () {
      final subscription = CustomerSubscription(
        id: 'sub_2',
        userId: 'user_2',
        plan: SubscriptionPlanType.starter,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 20)),
        pricePaid: const Money(500),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(20000),
        isDelivery: true,
      );

      // 3% of 20000 = 600
      expect(result.discount, const Money(600));
      expect(result.freeDelivery, true);
    });

    test('applies 15% discount for active VIP subscription', () {
      final subscription = CustomerSubscription(
        id: 'sub_3',
        userId: 'user_3',
        plan: SubscriptionPlanType.vip,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        expiryDate: DateTime.now().add(const Duration(days: 300)),
        pricePaid: const Money(2500),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(10000),
        isDelivery: false,
      );

      // 15% of 10000 = 1500
      expect(result.discount, const Money(1500));
      expect(result.freeDelivery, false);
    });

    test('returns zero discount for expired subscription', () {
      final subscription = CustomerSubscription(
        id: 'sub_4',
        userId: 'user_4',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(10000),
        isDelivery: true,
      );

      expect(result.discount, const Money(0));
      expect(result.freeDelivery, false);
    });

    test('returns zero discount for cancelled subscription', () {
      final subscription = CustomerSubscription(
        id: 'sub_5',
        userId: 'user_5',
        plan: SubscriptionPlanType.vip,
        status: SubscriptionStatus.cancelled,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 330)),
        pricePaid: const Money(2500),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        cancelledAt: DateTime.now().subtract(const Duration(days: 5)),
        cancelReason: 'No longer needed',
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(10000),
        isDelivery: true,
      );

      expect(result.discount, const Money(0));
      expect(result.freeDelivery, false);
    });

    test('does not apply free delivery for pickup orders', () {
      final subscription = CustomerSubscription(
        id: 'sub_6',
        userId: 'user_6',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 80)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(10000),
        isDelivery: false,
      );

      // 7% of 10000 = 700
      expect(result.discount, const Money(700));
      expect(result.freeDelivery, false);
    });

    test('returns zero discount for pending subscription', () {
      final subscription = CustomerSubscription(
        id: 'sub_7',
        userId: 'user_7',
        plan: SubscriptionPlanType.starter,
        status: SubscriptionStatus.pending,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        pricePaid: const Money(500),
        createdAt: DateTime.now(),
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(10000),
        isDelivery: true,
      );

      expect(result.discount, const Money(0));
      expect(result.freeDelivery, false);
    });

    test('handles zero subtotal correctly', () {
      final subscription = CustomerSubscription(
        id: 'sub_8',
        userId: 'user_8',
        plan: SubscriptionPlanType.vip,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 350)),
        pricePaid: const Money(2500),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      final result = service.applyBenefits(
        subscription: subscription,
        orderSubtotal: const Money(0),
        isDelivery: true,
      );

      expect(result.discount, const Money(0));
      expect(result.freeDelivery, true);
    });
  });

  group('CustomerSubscription.isActive', () {
    test('returns true for active subscription within expiry', () {
      final sub = CustomerSubscription(
        id: 'sub',
        userId: 'user',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 60)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(sub.isActive, true);
    });

    test('returns false for expired subscription', () {
      final sub = CustomerSubscription(
        id: 'sub',
        userId: 'user',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      );
      expect(sub.isActive, false);
    });

    test('returns false for cancelled subscription even if not expired', () {
      final sub = CustomerSubscription(
        id: 'sub',
        userId: 'user',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.cancelled,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 80)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(sub.isActive, false);
    });
  });

  group('CustomerSubscription.calculateDiscount', () {
    test('calculates correct discount for Plus plan', () {
      final sub = CustomerSubscription(
        id: 'sub',
        userId: 'user',
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 80)),
        pricePaid: const Money(1000),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      // 7% of 5000 = 350
      expect(sub.calculateDiscount(const Money(5000)), const Money(350));
    });

    test('returns zero for inactive subscription', () {
      final sub = CustomerSubscription(
        id: 'sub',
        userId: 'user',
        plan: SubscriptionPlanType.vip,
        status: SubscriptionStatus.expired,
        startDate: DateTime.now().subtract(const Duration(days: 200)),
        expiryDate: DateTime.now().subtract(const Duration(days: 10)),
        pricePaid: const Money(2500),
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      );
      expect(sub.calculateDiscount(const Money(10000)), const Money(0));
    });
  });
}
