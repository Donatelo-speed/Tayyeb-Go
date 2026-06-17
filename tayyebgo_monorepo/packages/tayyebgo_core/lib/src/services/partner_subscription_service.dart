import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/partner_subscription_model.dart';

class PartnerSubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<PartnerTier, PartnerTierInfo> tierDetails = {
    PartnerTier.free: PartnerTierInfo(
      tier: PartnerTier.free,
      name: 'Free',
      pricePerMonth: 0,
      commissionRate: 10.0,
      benefits: [
        'Basic restaurant listing',
        '10% commission per order',
        'Standard visibility',
      ],
    ),
    PartnerTier.growth: PartnerTierInfo(
      tier: PartnerTier.growth,
      name: 'Growth',
      pricePerMonth: 3000,
      commissionRate: 8.0,
      featuredPlacement: true,
      benefits: [
        'Featured placement in search',
        '8% commission per order',
        'Priority listing visibility',
        'Monthly performance reports',
      ],
    ),
    PartnerTier.premium: PartnerTierInfo(
      tier: PartnerTier.premium,
      name: 'Premium',
      pricePerMonth: 8000,
      commissionRate: 5.0,
      featuredPlacement: true,
      prioritySupport: true,
      analytics: true,
      promotions: true,
      benefits: [
        'Priority featured placement',
        '5% commission per order',
        'Priority support channel',
        'Advanced analytics dashboard',
        'Promotional campaign tools',
        'Dedicated account manager',
        'Early access to new features',
      ],
    ),
  };

  static const Map<PartnerTier, Duration> subscriptionDurations = {
    PartnerTier.free: Duration(days: 365),
    PartnerTier.growth: Duration(days: 30),
    PartnerTier.premium: Duration(days: 30),
  };

  Future<PartnerSubscription?> getSubscription(String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('partner_subscriptions')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: PartnerSubscriptionStatus.active.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return PartnerSubscription.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  Future<PartnerSubscription?> subscribe(String restaurantId, PartnerTier tier) async {
    try {
      final now = DateTime.now();
      final duration = subscriptionDurations[tier]!;
      final id = _firestore.collection('partner_subscriptions').doc().id;

      final subscription = PartnerSubscription(
        id: id,
        restaurantId: restaurantId,
        tier: tier,
        status: PartnerSubscriptionStatus.active,
        startDate: now,
        endDate: now.add(duration),
      );

      await _firestore
          .collection('partner_subscriptions')
          .doc(id)
          .set(subscription.toJSON());

      return subscription;
    } catch (e) {
      return null;
    }
  }

  Future<PartnerSubscription?> cancelSubscription(String restaurantId) async {
    try {
      final current = await getSubscription(restaurantId);
      if (current == null) return null;

      final cancelled = current.copyWith(
        status: PartnerSubscriptionStatus.cancelled,
      );

      await _firestore
          .collection('partner_subscriptions')
          .doc(current.id)
          .update({'status': PartnerSubscriptionStatus.cancelled.name});

      return cancelled;
    } catch (e) {
      return null;
    }
  }

  Future<PartnerSubscription?> upgradeTier(String restaurantId, PartnerTier newTier) async {
    try {
      final current = await getSubscription(restaurantId);

      if (current == null) {
        return subscribe(restaurantId, newTier);
      }

      if (current.tier == newTier) return current;

      final now = DateTime.now();
      final duration = subscriptionDurations[newTier]!;

      final upgraded = current.copyWith(
        tier: newTier,
        startDate: now,
        endDate: now.add(duration),
      );

      await _firestore
          .collection('partner_subscriptions')
          .doc(current.id)
          .update({
        'tier': newTier.name,
        'startDate': now.toIso8601String(),
        'endDate': now.add(duration).toIso8601String(),
      });

      return upgraded;
    } catch (e) {
      return null;
    }
  }

  PartnerTierInfo getTierBenefits(PartnerTier tier) {
    return tierDetails[tier]!;
  }

  double getCommissionRate(PartnerTier tier) {
    return tierDetails[tier]!.commissionRate;
  }

  List<PartnerTierInfo> getAllTiers() {
    return tierDetails.values.toList();
  }

  Future<void> checkExpiration(String restaurantId) async {
    try {
      final current = await getSubscription(restaurantId);
      if (current == null) return;

      if (current.status == PartnerSubscriptionStatus.active &&
          DateTime.now().isAfter(current.endDate)) {
        await _firestore
            .collection('partner_subscriptions')
            .doc(current.id)
            .update({'status': PartnerSubscriptionStatus.expired.name});
      }
    } catch (e) {
      // Silently handle expiration check failures
    }
  }
}
