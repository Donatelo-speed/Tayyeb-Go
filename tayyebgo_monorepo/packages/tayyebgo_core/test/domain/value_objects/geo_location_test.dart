import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/value_objects/geo_location.dart';

void main() {
  group('GeoLocation', () {
    group('distanceTo', () {
      test('same point returns 0', () {
        const a = GeoLocation(34.7369, 36.7131);
        expect(a.distanceTo(a), closeTo(0, 0.01));
      });

      test('known distance Homs to Damascus (~190km)', () {
        const homs = GeoLocation(34.7369, 36.7131);
        const damascus = GeoLocation(33.5138, 36.2765);
        final distance = homs.distanceTo(damascus);
        // Haversine distance is ~142km (straight-line, not road distance)
        expect(distance, closeTo(142000, 5000));
      });

      test('1 degree latitude ~ 111km', () {
        const a = GeoLocation(34.0, 36.0);
        const b = GeoLocation(35.0, 36.0);
        final distance = a.distanceTo(b);
        expect(distance, closeTo(111000, 5000));
      });

      test('symmetric: a→b equals b→a', () {
        const a = GeoLocation(34.7369, 36.7131);
        const b = GeoLocation(33.5138, 36.2765);
        expect(a.distanceTo(b), closeTo(b.distanceTo(a), 0.01));
      });
    });

    group('serialization', () {
      test('toMap', () {
        const loc = GeoLocation(34.7369, 36.7131);
        expect(loc.toMap(), {'latitude': 34.7369, 'longitude': 36.7131});
      });

      test('fromMap', () {
        final loc = GeoLocation.fromMap({'latitude': 34.7369, 'longitude': 36.7131});
        expect(loc.latitude, 34.7369);
        expect(loc.longitude, 36.7131);
      });

      test('roundtrip', () {
        const original = GeoLocation(34.7369, 36.7131);
        final restored = GeoLocation.fromMap(original.toMap());
        expect(restored.latitude, original.latitude);
        expect(restored.longitude, original.longitude);
      });
    });
  });
}
