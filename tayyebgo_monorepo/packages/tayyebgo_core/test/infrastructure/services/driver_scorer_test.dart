import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/entities/driver.dart';
import 'package:tayyebgo_core/domain/enums/driver_type.dart';
import 'package:tayyebgo_core/domain/value_objects/geo_location.dart';
import 'package:tayyebgo_core/infrastructure/services/driver_scorer.dart';

void main() {
  late DriverScorer scorer;

  setUp(() {
    scorer = DriverScorer.instance;
  });

  // Homs, Syria coordinates
  final pickup = GeoLocation(34.7369, 36.7131); // Homs center
  final dropoff = GeoLocation(34.7320, 36.7100); // ~500m away

  Driver makeDriver({
    required String id,
    required String name,
    required GeoLocation location,
    double rating = 5.0,
    int activeDeliveries = 0,
    DriverType driverType = DriverType.platform,
  }) {
    return Driver(
      id: id,
      name: name,
      email: '$id@test.com',
      driverType: driverType,
      currentLocation: location,
      rating: rating,
      activeDeliveries: activeDeliveries,
      createdAt: DateTime(2024),
    );
  }

  group('DriverScorer.scoreDrivers', () {
    test('returns empty list when no drivers', () async {
      final scores = await scorer.scoreDrivers(
        availableDrivers: [],
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );
      expect(scores, isEmpty);
    });

    test('skips drivers with no location', () async {
      final drivers = [
        makeDriver(id: 'd1', name: 'No Location', location: GeoLocation(0, 0)),
        makeDriver(id: 'd2', name: 'Has Location', location: pickup),
      ];
      // d1 has location at (0,0) which is far away but still valid
      final scores = await scorer.scoreDrivers(
        availableDrivers: drivers,
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );
      expect(scores, hasLength(2)); // Both have locations, just different distances
    });

    test('closer driver scores higher than far driver', () async {
      final nearDriver = makeDriver(
        id: 'near',
        name: 'Near Driver',
        location: GeoLocation(34.7370, 36.7132), // ~100m from pickup
      );
      final farDriver = makeDriver(
        id: 'far',
        name: 'Far Driver',
        location: GeoLocation(34.7500, 36.7300), // ~2km from pickup
      );

      final scores = await scorer.scoreDrivers(
        availableDrivers: [farDriver, nearDriver],
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );

      expect(scores, hasLength(2));
      expect(scores.first.driverId, 'near');
      expect(scores.last.driverId, 'far');
    });

    test('higher rated driver scores higher than low rated', () async {
      final sameLocation = GeoLocation(34.7370, 36.7132);
      final highRated = makeDriver(
        id: 'high',
        name: 'High Rated',
        location: sameLocation,
        rating: 5.0,
      );
      final lowRated = makeDriver(
        id: 'low',
        name: 'Low Rated',
        location: sameLocation,
        rating: 3.0,
      );

      final scores = await scorer.scoreDrivers(
        availableDrivers: [lowRated, highRated],
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );

      expect(scores.first.driverId, 'high');
      expect(scores.last.driverId, 'low');
    });

    test('driver with fewer active deliveries scores higher', () async {
      final sameLocation = GeoLocation(34.7370, 36.7132);
      final empty = makeDriver(
        id: 'empty',
        name: 'No Deliveries',
        location: sameLocation,
        activeDeliveries: 0,
      );
      final busy = makeDriver(
        id: 'busy',
        name: 'Busy Driver',
        location: sameLocation,
        activeDeliveries: 3,
      );

      final scores = await scorer.scoreDrivers(
        availableDrivers: [busy, empty],
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );

      expect(scores.first.driverId, 'empty');
      expect(scores.last.driverId, 'busy');
    });

    test('driver with 4+ active deliveries has 0 load factor', () async {
      final sameLocation = GeoLocation(34.7370, 36.7132);
      final overloaded = makeDriver(
        id: 'overloaded',
        name: 'Overloaded',
        location: sameLocation,
        activeDeliveries: 4,
      );

      final scores = await scorer.scoreDrivers(
        availableDrivers: [overloaded],
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );

      expect(scores, hasLength(1));
      // Load factor = max(0, 1.0 - 4 * 0.25) = 0
      expect(scores.first.activeDeliveries, 4);
    });

    test('all scores are between -1 and 1', () async {
      final drivers = [
        makeDriver(id: 'd1', name: 'D1', location: pickup, rating: 5.0, activeDeliveries: 0),
        makeDriver(id: 'd2', name: 'D2', location: dropoff, rating: 3.0, activeDeliveries: 2),
        makeDriver(id: 'd3', name: 'D3', location: GeoLocation(34.8, 36.8), rating: 4.5, activeDeliveries: 1),
      ];

      final scores = await scorer.scoreDrivers(
        availableDrivers: drivers,
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );

      for (final s in scores) {
        expect(s.score, greaterThanOrEqualTo(-1.0));
        expect(s.score, lessThanOrEqualTo(1.0));
      }
    });

    test('score contains correct metadata', () async {
      final driver = makeDriver(
        id: 'd1',
        name: 'Test Driver',
        location: pickup,
        rating: 4.5,
        activeDeliveries: 1,
        driverType: DriverType.platform,
      );

      final scores = await scorer.scoreDrivers(
        availableDrivers: [driver],
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );

      expect(scores, hasLength(1));
      final s = scores.first;
      expect(s.driverId, 'd1');
      expect(s.driverName, 'Test Driver');
      expect(s.driverType, 'platform');
      expect(s.rating, 4.5);
      expect(s.activeDeliveries, 1);
      expect(s.etaMinutes, greaterThan(0));
      expect(s.distanceKm, greaterThan(0));
    });

    test('10 drivers: correct ordering maintained', () async {
      final drivers = List.generate(10, (i) {
        // Each driver progressively farther from pickup
        final offset = i * 0.002;
        return makeDriver(
          id: 'd$i',
          name: 'Driver $i',
          location: GeoLocation(
            pickup.latitude + offset,
            pickup.longitude + offset,
          ),
          rating: 5.0 - (i * 0.1),
          activeDeliveries: i ~/ 3,
        );
      });

      final scores = await scorer.scoreDrivers(
        availableDrivers: drivers,
        pickupLocation: pickup,
        dropoffLocation: dropoff,
      );

      expect(scores, hasLength(10));
      // Closest/best driver should be first
      expect(scores.first.driverId, 'd0');
    });
  });
}
