import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnerTier {
  free,
  growth,
  premium,
}

enum PartnerSubscriptionStatus {
  active,
  expired,
  cancelled,
}

class PartnerSubscription {
  final String id;
  final String restaurantId;
  final PartnerTier tier;
  final PartnerSubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;

  PartnerSubscription({
    required this.id,
    required this.restaurantId,
    required this.tier,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive =>
      status == PartnerSubscriptionStatus.active &&
      DateTime.now().isBefore(endDate);

  int get daysRemaining {
    if (!isActive) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  double get commissionRate {
    switch (tier) {
      case PartnerTier.free:
        return 10.0;
      case PartnerTier.growth:
        return 8.0;
      case PartnerTier.premium:
        return 5.0;
    }
  }

  List<String> get benefits {
    switch (tier) {
      case PartnerTier.free:
        return [
          'Basic restaurant listing',
          '10% commission per order',
          'Standard visibility',
        ];
      case PartnerTier.growth:
        return [
          'Featured placement in search',
          '8% commission per order',
          'Priority listing visibility',
          'Monthly performance reports',
        ];
      case PartnerTier.premium:
        return [
          'Priority featured placement',
          '5% commission per order',
          'Priority support channel',
          'Advanced analytics dashboard',
          'Promotional campaign tools',
          'Dedicated account manager',
          'Early access to new features',
        ];
    }
  }

  int get pricePerMonth {
    switch (tier) {
      case PartnerTier.free:
        return 0;
      case PartnerTier.growth:
        return 3000;
      case PartnerTier.premium:
        return 8000;
    }
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'tier': tier.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory PartnerSubscription.fromJSON(Map<String, dynamic> json) {
    return PartnerSubscription(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      tier: PartnerTier.values.byName(json['tier'] as String),
      status: PartnerSubscriptionStatus.values.byName(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  factory PartnerSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerSubscription.fromJSON({...data, 'id': doc.id});
  }

  PartnerSubscription copyWith({
    String? id,
    String? restaurantId,
    PartnerTier? tier,
    PartnerSubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PartnerSubscription(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class PartnerTierInfo {
  final PartnerTier tier;
  final String name;
  final int pricePerMonth;
  final double commissionRate;
  final bool featuredPlacement;
  final bool prioritySupport;
  final bool analytics;
  final bool promotions;
  final List<String> benefits;

  const PartnerTierInfo({
    required this.tier,
    required this.name,
    required this.pricePerMonth,
    required this.commissionRate,
    this.featuredPlacement = false,
    this.prioritySupport = false,
    this.analytics = false,
    this.promotions = false,
    required this.benefits,
  });
}
