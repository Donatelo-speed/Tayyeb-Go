abstract final class AppConstants {
  AppConstants._();

  static const double taxRate = 0.08;
  static const double commissionPercent = 15.0;
  static const double deliveryFee = 5.0;
  static const double freeDeliveryThreshold = 50.0;
  static const double defaultLatitude = 34.7308;
  static const double defaultLongitude = 36.7133;
  static const int paginationLimit = 20;
  static const int searchLimit = 20;
  static const Duration authTimeout = Duration(seconds: 10);
  static const Duration splashDuration = Duration(milliseconds: 2600);
  static const int maxLoginAttempts = 5;
  static const Duration loginLockoutDuration = Duration(minutes: 15);
}
