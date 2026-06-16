import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/entities/customer_subscription.dart';
import 'package:tayyebgo_core/domain/enums/subscription_plan.dart';
import 'package:tayyebgo_core/domain/enums/subscription_status.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';
import 'package:tayyebgo_core/infrastructure/services/subscription_service.dart';

void main() {
  late SubscriptionService service;

  setUp(() {
    service = SubscriptionService.instance;
  });

  group('SubscriptionService.applyBenefits', () {
    test('applies discount and free delivery for active subscription', () {
      final sub = _makeSub(status: SubscriptionStatus.active);
      final result = service.applyBenefits(
        subscription: sub,
        orderSubtotal: const Money(10000),
        isDelivery: true,
      );
      expect(result.discount.amountInCents, 500);
      expect(result.freeDelivery, isTrue);
    });

    test('returns zero discount for expired subscription', () {
      final sub = _makeSub(
        status: SubscriptionStatus.active,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final result = service.applyBenefits(
        subscription: sub,
        orderSubtotal: const Money(10000),
        isDelivery: true,
      );
      expect(result.discount.amountInCents, 0);
      expect(result.freeDelivery, isFalse);
    });

    test('returns no free delivery when isDelivery is false', () {
      final sub = _makeSub(status: SubscriptionStatus.active);
      final result = service.applyBenefits(
        subscription: sub,
        orderSubtotal: const Money(10000),
        isDelivery: false,
      );
      expect(result.discount.amountInCents, 500);
      expect(result.freeDelivery, isFalse);
    });

    test('plus plan applies 10% discount', () {
      final sub = _makeSub(
        plan: SubscriptionPlanType.plus,
        status: SubscriptionStatus.active,
      );
      final result = service.applyBenefits(
        subscription: sub,
        orderSubtotal: const Money(20000),
        isDelivery: true,
      );
      expect(result.discount.amountInCents, 2000);
    });

    test('premium plan applies 15% discount', () {
      final sub = _makeSub(
        plan: SubscriptionPlanType.premium,
        status: SubscriptionStatus.active,
      );
      final result = service.applyBenefits(
        subscription: sub,
        orderSubtotal: const Money(10000),
        isDelivery: true,
      );
      expect(result.discount.amountInCents, 1500);
    });
  });

  group('SubscriptionService.isExpiringSoon', () {
    test('returns true when 3 days remaining', () {
      final sub = _makeSub(
        expiryDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(service.isExpiringSoon(sub), isTrue);
    });

    test('returns true when 7 days remaining', () {
      final sub = _makeSub(
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );
      expect(service.isExpiringSoon(sub), isTrue);
    });

    test('returns false when 8 days remaining', () {
      final sub = _makeSub(
        expiryDate: DateTime.now().add(const Duration(days: 8)),
      );
      expect(service.isExpiringSoon(sub), isFalse);
    });

    test('returns false when subscription is expired', () {
      final sub = _makeSub(
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(service.isExpiringSoon(sub), isFalse);
    });
  });
}

CustomerSubscription _makeSub({
  SubscriptionPlanType plan = SubscriptionPlanType.basic,
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? expiryDate,
}) {
  final now = DateTime.now();
  return CustomerSubscription(
    id: 'sub-1',
    userId: 'user-1',
    plan: plan,
    status: status,
    startDate: now,
    expiryDate: expiryDate ?? now.add(const Duration(days: 30)),
    pricePaid: Money(plan.priceInCents),
    createdAt: now,
  );
}
