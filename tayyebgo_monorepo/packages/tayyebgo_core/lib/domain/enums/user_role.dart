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

  /// Which app this role primarily belongs to.
  String get appTarget => switch (this) {
        UserRole.superAdmin => 'admin',
        UserRole.restaurantOwner || UserRole.cashier => 'partner',
        UserRole.driver => 'driver',
        UserRole.customer => 'customer',
      };

  /// Roles that can access the partner app.
  static const List<UserRole> partnerRoles = [
    UserRole.restaurantOwner,
    UserRole.cashier,
    UserRole.superAdmin,
  ];

  /// Roles that can access the admin app.
  static const List<UserRole> adminRoles = [
    UserRole.superAdmin,
  ];

  /// Roles that can access the driver app.
  static const List<UserRole> driverRoles = [
    UserRole.driver,
    UserRole.superAdmin,
  ];

  /// Roles that can access the customer app.
  static const List<UserRole> customerRoles = [
    UserRole.customer,
    UserRole.superAdmin,
  ];

  /// Returns the allowed roles for a given app target.
  static List<UserRole> allowedRolesForApp(String app) => switch (app) {
        'admin' => adminRoles,
        'partner' => partnerRoles,
        'driver' => driverRoles,
        'customer' => customerRoles,
        _ => UserRole.values,
      };

  /// Whether this role can access the partner app.
  bool get canAccessPartner => partnerRoles.contains(this);

  /// Whether this role can access the admin app.
  bool get canAccessAdmin => adminRoles.contains(this);

  /// Whether this role can access the driver app.
  bool get canAccessDriver => driverRoles.contains(this);

  /// Whether this role can access the customer app.
  bool get canAccessCustomer => customerRoles.contains(this);

  /// Whether this role is an admin-level role (elevated access).
  bool get isAdminLevel => this == UserRole.superAdmin;

  /// Whether this role is a partner-level role.
  bool get isPartnerRole =>
      this == UserRole.restaurantOwner || this == UserRole.cashier;
}
