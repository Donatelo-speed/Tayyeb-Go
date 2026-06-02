enum UserRole {
  superAdmin('superAdmin', 'Super Admin'),
  restaurantOwner('restaurantOwner', 'Restaurant Owner'),
  cashier('cashier', 'Cashier'),
  driver('driver', 'Driver'),
  customer('customer', 'Customer');

  final String value;
  final String displayName;
  const UserRole(this.value, this.displayName);

  static UserRole fromValue(String v) =>
      UserRole.values.firstWhere((r) => r.value == v, orElse: () => customer);

  static UserRole fromString(String? v) => fromValue(v ?? '');
}
