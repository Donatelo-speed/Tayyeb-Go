enum FulfillmentType {
  delivery('delivery'),
  pickup('pickup');

  final String value;
  const FulfillmentType(this.value);

  static FulfillmentType fromValue(String v) =>
      FulfillmentType.values.firstWhere((f) => f.value == v, orElse: () => delivery);
}
