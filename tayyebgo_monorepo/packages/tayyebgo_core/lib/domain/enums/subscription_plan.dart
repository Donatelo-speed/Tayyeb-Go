enum SubscriptionPlanType {
  starter('starter', 'Starter', 1, 500, [
    'free_delivery_first_3_orders',
    '3_percent_discount',
    'priority_offers',
  ]),
  plus('plus', 'Plus', 3, 1000, [
    'free_delivery',
    '7_percent_discount',
    'monthly_exclusive_offers',
    'priority_support',
  ]),
  pro('pro', 'Pro', 6, 2000, [
    'free_delivery',
    '12_percent_discount',
    'exclusive_deals',
    'early_access',
    'priority_support',
    'vip_badge',
  ]),
  vip('vip', 'VIP', 12, 2500, [
    'free_delivery',
    '15_percent_discount',
    'exclusive_deals',
    'early_access',
    'priority_support',
    'vip_badge',
    'dedicated_support',
    'monthly_free_item',
    'double_rewards',
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
        orElse: () => starter,
      );

  String get priceDisplay => '\$${(priceInCents / 100).toStringAsFixed(0)}';

  int get freeDeliveryLimit => -1;

  double get discountPercent => switch (this) {
        SubscriptionPlanType.starter => 3.0,
        SubscriptionPlanType.plus => 7.0,
        SubscriptionPlanType.pro => 12.0,
        SubscriptionPlanType.vip => 15.0,
      };

  String get monthlyPriceDisplay {
    final monthly = priceInCents / 100 / durationMonths;
    return '\$${monthly.toStringAsFixed(2)}/mo';
  }

  bool get isPopular => this == SubscriptionPlanType.plus;
  bool get isBestValue => this == SubscriptionPlanType.pro;
  bool get isBestDeal => this == SubscriptionPlanType.vip;
}
