enum SubscriptionStatus {
  active('active'),
  expired('expired'),
  cancelled('cancelled'),
  pending('pending');

  final String value;
  const SubscriptionStatus(this.value);

  static SubscriptionStatus fromValue(String v) =>
      SubscriptionStatus.values.firstWhere(
        (s) => s.value == v,
        orElse: () => pending,
      );

  bool get isActive => this == active;
  bool get canBeRenewable => this == expired || this == cancelled;
}
