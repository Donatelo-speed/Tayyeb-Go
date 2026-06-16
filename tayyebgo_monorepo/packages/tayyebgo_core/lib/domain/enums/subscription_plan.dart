enum SubscriptionPlanType {
  basic('basic', 'Basic', 1, 10000, [
    'free_delivery',
    '5_percent_discount',
    'priority_offers',
  ]),
  plus('plus', 'Plus', 3, 25000, [
    'free_delivery',
    '10_percent_discount',
    'monthly_offers',
    'priority_support',
  ]),
  premium('premium', 'Premium', 6, 45000, [
    'free_delivery',
    '15_percent_discount',
    'exclusive_deals',
    'early_access',
    'priority_support',
  ]);

  final String value;
  final String displayName;
  final int durationMonths;
  final int priceInCents;
  final List<String> benefits;

  const SubscriptionPlanType(
    this.value,
    this.displayName,
    this.durationMonths,
    this.priceInCents,
    this.benefits,
  );

  static SubscriptionPlanType fromValue(String v) =>
      SubscriptionPlanType.values.firstWhere(
        (p) => p.value == v,
        orElse: () => basic,
      );

  String get priceDisplay => '\$${(priceInCents / 100).toStringAsFixed(0)}';

  int get freeDeliveryLimit => -1;

  double get discountPercent => switch (this) {
        SubscriptionPlanType.basic => 5.0,
        SubscriptionPlanType.plus => 10.0,
        SubscriptionPlanType.premium => 15.0,
      };
}
