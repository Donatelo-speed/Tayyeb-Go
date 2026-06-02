import 'dart:math' as math;
import '../../domain/entities/driver.dart';
import '../../domain/entities/dispatch_request.dart';
import '../../domain/services/i_auto_dispatcher.dart';
import '../../domain/value_objects/geo_location.dart';

class DriverScorer implements IDriverScorer {
  static final DriverScorer instance = DriverScorer._();
  DriverScorer._();
  static const double _etaWeight = 0.40;
  static const double _ratingWeight = 0.25;
  static const double _loadWeight = 0.20;
  static const double _distanceWeight = 0.15;

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
      final loadFactor = math.max(0, 1.0 - driver.activeDeliveries * 0.25);

      final etaNorm = _normalize(etaMin, 2, 60);
      final ratingNorm = driver.rating / 5.0;
      final distanceNorm = _normalize(distTotal / 1000, 0.5, 20);

      final score = (etaNorm * _etaWeight * -1 +
              ratingNorm * _ratingWeight +
              loadFactor * _loadWeight +
              distanceNorm * _distanceWeight * -1);

      scores.add(DriverScore(
        driverId: driver.id,
        driverName: driver.name,
        driverType: driver.driverType.value,
        etaMinutes: etaMin,
        distanceKm: distTotal / 1000,
        rating: driver.rating,
        activeDeliveries: driver.activeDeliveries,
        score: score,
      ));
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  double _normalize(double value, double min, double max) =>
      (value - min) / (max - min);
}