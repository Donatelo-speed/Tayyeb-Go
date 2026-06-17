import 'dart:math';

import '../models/driver_subscription_model.dart';

class DriverSubscriptionService {
  static const Map<DriverSubscriptionPlan, DriverSubscriptionPlanInfo> planDetails = {
    DriverSubscriptionPlan.basic: DriverSubscriptionPlanInfo(
      plan: DriverSubscriptionPlan.basic,
      name: 'Basic',
      pricePerMonth: 0,
      maxConcurrentDeliveries: 1,
      benefits: [
        '1 delivery at a time',
        'Standard dispatch',
        'Basic route suggestions',
      ],
    ),
    DriverSubscriptionPlan.pro: DriverSubscriptionPlanInfo(
      plan: DriverSubscriptionPlan.pro,
      name: 'Pro',
      pricePerMonth: 5000,
      maxConcurrentDeliveries: 3,
      priorityDispatch: true,
      benefits: [
        'Up to 3 concurrent deliveries',
        'Priority dispatch',
        'Optimized route suggestions',
        'Earnings analytics dashboard',
        'Priority support',
      ],
    ),
    DriverSubscriptionPlan.premium: DriverSubscriptionPlanInfo(
      plan: DriverSubscriptionPlan.premium,
      name: 'Premium',
      pricePerMonth: 12000,
      maxConcurrentDeliveries: 5,
      priorityDispatch: true,
      batchedRoutes: true,
      benefits: [
        'Up to 5 concurrent deliveries',
        'Highest priority dispatch',
        'Batched route optimization',
        'Advanced earnings analytics',
        'Dedicated support line',
        'Surge earnings bonus',
      ],
    ),
  };

  static const Map<DriverSubscriptionPlan, Duration> subscriptionDurations = {
    DriverSubscriptionPlan.basic: Duration(days: 365),
    DriverSubscriptionPlan.pro: Duration(days: 30),
    DriverSubscriptionPlan.premium: Duration(days: 30),
  };

  final Map<String, DriverSubscription> _subscriptions = {};

  DriverSubscription? getSubscription(String driverId) {
    return _subscriptions[driverId];
  }

  DriverSubscription subscribe(String driverId, DriverSubscriptionPlan planType) {
    final now = DateTime.now();
    final duration = subscriptionDurations[planType]!;
    final id = _generateId();

    final subscription = DriverSubscription(
      id: id,
      driverId: driverId,
      planType: planType,
      status: DriverSubscriptionStatus.active,
      startDate: now,
      endDate: now.add(duration),
      autoRenew: planType != DriverSubscriptionPlan.basic,
    );

    _subscriptions[driverId] = subscription;
    return subscription;
  }

  DriverSubscription? cancelSubscription(String driverId) {
    final current = _subscriptions[driverId];
    if (current == null) return null;

    final cancelled = current.copyWith(
      status: DriverSubscriptionStatus.cancelled,
      autoRenew: false,
    );

    _subscriptions[driverId] = cancelled;
    return cancelled;
  }

  DriverSubscription? renewSubscription(String driverId) {
    final current = _subscriptions[driverId];
    if (current == null) return null;

    final duration = subscriptionDurations[current.planType]!;
    final newEndDate = current.endDate.add(duration);

    final renewed = current.copyWith(
      status: DriverSubscriptionStatus.active,
      startDate: current.endDate,
      endDate: newEndDate,
    );

    _subscriptions[driverId] = renewed;
    return renewed;
  }

  DriverSubscription? checkExpiration(String driverId) {
    final current = _subscriptions[driverId];
    if (current == null) return null;

    if (current.status == DriverSubscriptionStatus.active &&
        DateTime.now().isAfter(current.endDate)) {
      if (current.autoRenew) {
        return renewSubscription(driverId);
      }

      final downgraded = current.copyWith(
        status: DriverSubscriptionStatus.expired,
        planType: DriverSubscriptionPlan.basic,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(subscriptionDurations[DriverSubscriptionPlan.basic]!),
      );

      _subscriptions[driverId] = downgraded;
      return downgraded;
    }

    return current;
  }

  DriverSubscriptionPlanInfo getPlanBenefits(DriverSubscriptionPlan planType) {
    return planDetails[planType]!;
  }

  List<DriverSubscriptionPlanInfo> getAllPlans() {
    return planDetails.values.toList();
  }

  String _generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
