enum VerticalType {
  restaurant('restaurant', 'Restaurant'),
  grocery('grocery', 'Grocery'),
  pharmacy('pharmacy', 'Pharmacy'),
  retail('retail', 'Retail');

  final String value;
  final String displayName;

  const VerticalType(this.value, this.displayName);

  static VerticalType fromValue(String value) {
    return VerticalType.values.firstWhere(
      (v) => v.value == value,
      orElse: () => VerticalType.restaurant,
    );
  }
}
