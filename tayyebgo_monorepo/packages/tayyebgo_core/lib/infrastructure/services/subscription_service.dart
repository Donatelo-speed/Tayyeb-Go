import '../../domain/entities/customer_subscription.dart';
import '../../domain/enums/subscription_plan.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/repositories/i_subscription_repository.dart';
import '../../domain/value_objects/money.dart';
import '../repositories/firebase_subscription_repository.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  ISubscriptionRepository get _repo =>
      FirebaseSubscriptionRepository.instance;

  Stream<CustomerSubscription?> watchActiveSubscription(String userId) =>
      _repo.watchActiveSubscription(userId);

  Future<CustomerSubscription?> getActiveSubscription(String userId) =>
      _repo.getActiveSubscription(userId);

  Future<List<CustomerSubscription>> getSubscriptionHistory(String userId) =>
      _repo.getSubscriptionHistory(userId);

  Future<CustomerSubscription?> subscribe({
    required String userId,
    required SubscriptionPlanType plan,
    required String paymentTransactionId,
  }) async {
    final existing = await _repo.getActiveSubscription(userId);
    if (existing != null && existing.isActive) {
      return null;
    }

    final now = DateTime.now();
    final expiry = DateTime(
      now.year + plan.durationMonths ~/ 12,
      now.month + plan.durationMonths % 12,
      now.day,
    );

    final subscription = CustomerSubscription(
      id: '',
      userId: userId,
      plan: plan,
      status: SubscriptionStatus.active,
      startDate: now,
      expiryDate: expiry,
      pricePaid: Money(plan.priceInCents),
      paymentTransactionId: paymentTransactionId,
      createdAt: now,
    );

    await _repo.createSubscription(subscription);
    return subscription;
  }

  ({Money discount, bool freeDelivery}) applyBenefits({
    required CustomerSubscription subscription,
    required Money orderSubtotal,
    required bool isDelivery,
  }) {
    if (!subscription.isActive) {
      return (discount: const Money(0), freeDelivery: false);
    }
    return (
      discount: subscription.calculateDiscount(orderSubtotal),
      freeDelivery: isDelivery && subscription.hasFreeDelivery,
    );
  }

  Future<void> cancel(String subscriptionId, String reason) async {
    await _repo.cancelSubscription(subscriptionId, reason);
  }

  bool isExpiringSoon(CustomerSubscription subscription) {
    return subscription.isActive && subscription.daysRemaining <= 7;
  }
}
