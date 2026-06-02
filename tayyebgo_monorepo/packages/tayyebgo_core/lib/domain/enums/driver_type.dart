enum DriverType {
  platform('platform', 'Platform Driver'),
  store('store', 'Store Driver');

  final String value;
  final String displayName;
  const DriverType(this.value, this.displayName);

  static DriverType fromValue(String v) =>
      DriverType.values.firstWhere((d) => d.value == v, orElse: () => platform);

  static DriverType fromString(String? v) => fromValue(v ?? '');
}
