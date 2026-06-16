import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';
import 'package:tayyebgo_core/infrastructure/services/commission_calculator.dart';

void main() {
  late CommissionCalculator calculator;

  setUp(() {
    calculator = CommissionCalculator();
  });

  group('CommissionCalculator.calculate', () {
    test('15% commission on 10000 cents', () {
      final result = calculator.calculate(const Money(10000), 15.0);
      expect(result.amountInCents, 1500);
    });

    test('10% commission on 5000 cents', () {
      final result = calculator.calculate(const Money(5000), 10.0);
      expect(result.amountInCents, 500);
    });

    test('0% commission returns 0', () {
      final result = calculator.calculate(const Money(10000), 0.0);
      expect(result.amountInCents, 0);
    });

    test('100% commission returns full amount', () {
      final result = calculator.calculate(const Money(10000), 100.0);
      expect(result.amountInCents, 10000);
    });

    test('rounds to nearest cent', () {
      // 333 * 15 / 100 = 49.95 → rounds to 50
      final result = calculator.calculate(const Money(333), 15.0);
      expect(result.amountInCents, 50);
    });

    test('zero amount returns 0', () {
      final result = calculator.calculate(const Money(0), 15.0);
      expect(result.amountInCents, 0);
    });

    test('25% commission on 9999 cents', () {
      // 9999 * 25 / 100 = 2499.75 → rounds to 2500
      final result = calculator.calculate(const Money(9999), 25.0);
      expect(result.amountInCents, 2500);
    });
  });

  group('CommissionCalculator.netAfterCommission', () {
    test('15% commission on 10000 cents leaves 8500', () {
      final result = calculator.netAfterCommission(const Money(10000), 15.0);
      expect(result.amountInCents, 8500);
    });

    test('0% commission leaves full amount', () {
      final result = calculator.netAfterCommission(const Money(10000), 0.0);
      expect(result.amountInCents, 10000);
    });

    test('100% commission leaves 0', () {
      final result = calculator.netAfterCommission(const Money(10000), 100.0);
      expect(result.amountInCents, 0);
    });

    test('10% commission on 500 cents', () {
      final result = calculator.netAfterCommission(const Money(500), 10.0);
      expect(result.amountInCents, 450);
    });

    test('zero amount returns 0', () {
      final result = calculator.netAfterCommission(const Money(0), 15.0);
      expect(result.amountInCents, 0);
    });

    test('commission + net = gross (no rounding errors)', () {
      const gross = Money(10000);
      final commission = calculator.calculate(gross, 15.0);
      final net = calculator.netAfterCommission(gross, 15.0);
      expect(commission.amountInCents + net.amountInCents, gross.amountInCents);
    });
  });
}
