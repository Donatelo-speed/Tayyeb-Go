import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/value_objects/unit_economics.dart';

void main() {
  group('UnitEconomics', () {
    test('calculate basic economics', () {
      final ue = UnitEconomics.calculate(
        orderTotal: 100000,
        deliveryFeeCharged: 10000,
        commissionPercent: 10.0,
      );

      expect(ue.orderTotal, 100000);
      expect(ue.deliveryFeeCharged, 10000);
      expect(ue.commissionPercent, 10.0);
      expect(ue.commissionAmount, 10000.0);
      expect(ue.driverEarnings, 8000.0);
      expect(ue.platformFee, 2000.0);
    });

    test('profit calculation', () {
      final ue = UnitEconomics.calculate(
        orderTotal: 100000,
        deliveryFeeCharged: 10000,
        commissionPercent: 10.0,
        driverCost: 12000,
        platformCost: 2000,
      );

      final totalRevenue = ue.commissionAmount + ue.platformFee;
      final totalCost = ue.driverCost + ue.platformCost;
      expect(ue.profit, totalRevenue - totalCost);
    });

    test('isProfitable returns true when profit > 0', () {
      final ue = UnitEconomics.calculate(
        orderTotal: 200000,
        deliveryFeeCharged: 20000,
        commissionPercent: 10.0,
        driverCost: 12000,
        platformCost: 2000,
      );

      expect(ue.isProfitable, true);
    });

    test('isProfitable returns false when profit < 0', () {
      final ue = UnitEconomics.calculate(
        orderTotal: 5000,
        deliveryFeeCharged: 5000,
        commissionPercent: 10.0,
        driverCost: 12000,
        platformCost: 2000,
      );

      expect(ue.isProfitable, false);
    });

    test('toMap returns correct structure', () {
      final ue = UnitEconomics.calculate(
        orderTotal: 100000,
        deliveryFeeCharged: 10000,
        commissionPercent: 10.0,
      );

      final map = ue.toMap();
      expect(map['orderTotal'], 100000);
      expect(map['commissionAmount'], 10000.0);
      expect(map.containsKey('profit'), true);
      expect(map.containsKey('margin'), true);
    });

    test('margin calculation', () {
      final ue = UnitEconomics.calculate(
        orderTotal: 100000,
        deliveryFeeCharged: 20000,
        commissionPercent: 10.0,
        driverCost: 8000,
        platformCost: 2000,
      );

      expect(ue.margin, isA<double>());
      expect(ue.margin, greaterThan(0));
    });

    test('toString returns readable string', () {
      final ue = UnitEconomics.calculate(
        orderTotal: 100000,
        deliveryFeeCharged: 10000,
        commissionPercent: 10.0,
      );

      expect(ue.toString(), contains('UnitEconomics'));
    });
  });
}
