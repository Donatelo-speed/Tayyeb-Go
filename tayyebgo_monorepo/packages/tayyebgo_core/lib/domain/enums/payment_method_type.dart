enum PaymentMethodType {
  stripe('stripe', 'Visa / Mastercard'),
  shamCash('sham_cash', 'Sham Cash');

  final String value;
  final String displayName;
  const PaymentMethodType(this.value, this.displayName);

  static PaymentMethodType fromValue(String v) =>
      PaymentMethodType.values.firstWhere((r) => r.value == v, orElse: () => shamCash);
}
