abstract final class Routes {
  Routes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String forbidden = '/forbidden';
  static const String splash = '/splash';

  static const String partnerRoot = '/';
  static const String partnerCashier = '/cashier';
  static const String partnerOwner = '/owner';

  static const String adminRoot = '/';
  static const String adminRestaurants = '/restaurants';
  static const String adminUsers = '/users';
  static const String adminDrivers = '/drivers';
  static const String adminLiveMap = '/live-map';
  static const String adminCommissions = '/commissions';
  static const String adminNotifications = '/notifications';
  static const String adminSettings = '/settings';

  static const String driverRoot = '/';
  static const String driverActive = '/delivery/:orderId';
  static const String driverProfile = '/profile';

  static const String customerRoot = '/';
  static const String customerRestaurant = '/restaurant/:restaurantId';
  static const String customerCart = '/cart';
  static const String customerCheckout = '/checkout';
  static const String customerTracking = '/order/:orderId/tracking';
  static const String customerProfile = '/profile';
  static const String customerOrders = '/my-orders';

  static String driverActivePath(String orderId) => '/delivery/$orderId';
  static String customerRestaurantPath(String restaurantId) => '/restaurant/$restaurantId';
  static String customerTrackingPath(String orderId) => '/order/$orderId/tracking';
}
