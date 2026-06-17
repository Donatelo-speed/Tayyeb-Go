import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/entities/zone.dart';
import 'package:tayyebgo_core/domain/value_objects/geo_location.dart';
import 'package:tayyebgo_core/infrastructure/services/pricing_engine.dart';

void main() {
  group('PricingEngine', () {
    late PricingEngine engine;

    setUp(() {
      engine = const PricingEngine();
    });

    test('basic calculation with default rules', () {
      final result = engine.calculate(
        subtotal: 50000,
        restaurantLocation: const GeoLocation(34.7369, 36.7131),
        deliveryLocation: const GeoLocation(34.7500, 36.7200),
      );

      expect(result.subtotal, 50000);
      expect(result.tax, greaterThan(0));
      expect(result.grandTotal, greaterThan(50000));
    });

    test('free delivery for high subtotal', () {
      final result = engine.calculate(
        subtotal: 60000,
        restaurantLocation: const GeoLocation(34.7369, 36.7131),
        deliveryLocation: const GeoLocation(34.7500, 36.7200),
      );

      expect(result.deliveryFee, 0);
    });

    test('free delivery for subscribers', () {
      final result = engine.calculate(
        subtotal: 30000,
        restaurantLocation: const GeoLocation(34.7369, 36.7131),
        deliveryLocation: const GeoLocation(34.7500, 36.7200),
        isSubscriber: true,
      );

      expect(result.deliveryFee, 0);
    });

    test('discount reduces grand total', () {
      final withoutDiscount = engine.calculate(
        subtotal: 50000,
        restaurantLocation: const GeoLocation(34.7369, 36.7131),
        deliveryLocation: const GeoLocation(34.7500, 36.7200),
      );

      final withDiscount = engine.calculate(
        subtotal: 50000,
        restaurantLocation: const GeoLocation(34.7369, 36.7131),
        deliveryLocation: const GeoLocation(34.7500, 36.7200),
        discount: 5000,
      );

      expect(withDiscount.grandTotal, lessThan(withoutDiscount.grandTotal));
    });

    test('zone fee overrides default', () {
      final zone = ZoneModel(
        id: 'test',
        name: 'Test Zone',
        deliveryFee: 8000,
        perKmFee: 1000,
        createdAt: DateTime.now(),
      );

      final result = engine.calculate(
        subtotal: 30000,
        restaurantLocation: const GeoLocation(34.7369, 36.7131),
        deliveryLocation: const GeoLocation(34.7500, 36.7200),
        zone: zone,
      );

      expect(result.zoneFee, 8000);
      expect(result.zoneName, 'Test Zone');
    });

    test('flatDeliveryFee returns 0 above threshold', () {
      expect(engine.flatDeliveryFee(60000), 0.0);
    });

    test('flatDeliveryFee returns base below threshold', () {
      expect(engine.flatDeliveryFee(30.0), 5.0);
    });
  });

  group('PricingRules', () {
    test('defaultRules has sensible defaults', () {
      final rules = PricingRules.defaultRules;
      expect(rules.baseDeliveryFee, 5.0);
      expect(rules.perKmFee, 0.5);
      expect(rules.taxRate, 0.08);
      expect(rules.maxDeliveryDistanceKm, 15.0);
    });
  });
}
