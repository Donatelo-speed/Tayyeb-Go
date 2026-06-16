import 'dart:math' as math;
import '../../domain/entities/driver.dart';
import '../../domain/entities/dispatch_request.dart';
import '../../domain/services/i_auto_dispatcher.dart';
import '../../domain/value_objects/geo_location.dart';

class DriverScorer implements IDriverScorer {
  static final DriverScorer instance = DriverScorer._();
  DriverScorer._();

  /// Blueprint weights: Distance 40%, Rating 20%, Completion 20%, Workload 10%, Subscription 10%
  static const double _distanceWeight = 0.40;
  static const double _ratingWeight = 0.20;
  static const double _completionWeight = 0.20;
  static const double _workloadWeight = 0.10;
  static const double _subscriptionWeight = 0.10;

  /// Threshold for max completed deliveries used in normalization
  static const int _maxCompletedDeliveries = 5000;

  @override
  Future<List<DriverScore>> scoreDrivers({
    required List<Driver> availableDrivers,
    required GeoLocation pickupLocation,
    required GeoLocation dropoffLocation,
  }) async {
    final scores = <DriverScore>[];
    for (final driver in availableDrivers) {
      if (driver.currentLocation == null) continue;

      final distToPickup = driver.currentLocation!.distanceTo(pickupLocation);
      final distTotal = distToPickup + pickupLocation.distanceTo(dropoffLocation);
      final etaMin = (distToPickup / 500.0).clamp(2.0, 60.0);

      /// Distance score: closer is better (inverted — lower distance = higher score)
      final distanceNorm = _normalize(distTotal / 1000, 0.5, 20);
      final distanceScore = 1.0 - distanceNorm.clamp(0.0, 1.0);

      /// Rating score: higher is better (0-5 scale normalized to 0-1)
      final ratingScore = driver.rating / 5.0;

      /// Completion score: more completed deliveries = higher score (normalized)
      final completionNorm = _normalize(
        driver.completedDeliveries.toDouble(),
        0,
        _maxCompletedDeliveries.toDouble(),
      );
      final completionScore = completionNorm.clamp(0.0, 1.0);

      /// Workload score: fewer active deliveries = higher score
      final workloadScore = (math.max(0, 1.0 - driver.activeDeliveries * 0.25)).toDouble();

      /// Subscription score: subscribed drivers get priority
      final subscriptionScore = driver.isSubscribed ? 1.0 : 0.0;

      /// Weighted sum
      final score = (distanceScore * _distanceWeight +
              ratingScore * _ratingWeight +
              completionScore * _completionWeight +
              workloadScore * _workloadWeight +
              subscriptionScore * _subscriptionWeight);

      scores.add(DriverScore(
        driverId: driver.id,
        driverName: driver.name,
        driverType: driver.driverType.value,
        etaMinutes: etaMin,
        distanceKm: distTotal / 1000,
        rating: driver.rating,
        activeDeliveries: driver.activeDeliveries,
        completedDeliveries: driver.completedDeliveries,
        isSubscribed: driver.isSubscribed,
        score: score,
        distanceScore: distanceScore,
        ratingScore: ratingScore,
        completionScore: completionScore,
        workloadScore: workloadScore,
        subscriptionScore: subscriptionScore,
      ));
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  double _normalize(double value, double min, double max) =>
      (value - min) / (max - min);
}