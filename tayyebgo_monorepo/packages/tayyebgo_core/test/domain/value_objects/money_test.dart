import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';

void main() {
  group('Money', () {
    group('construction', () {
      test('creates from cents', () {
        const money = Money(1500);
        expect(money.amountInCents, 1500);
      });

      test('creates from dollars', () {
        final money = Money.fromDollars(15.99);
        expect(money.amountInCents, 1599);
      });

      test('creates from dollars with rounding', () {
        final money = Money.fromDollars(10.005);
        expect(money.amountInCents, 1001);
      });

      test('zero money', () {
        const money = Money(0);
        expect(money.amountInCents, 0);
        expect(money.inDollars, 0.0);
      });
    });

    group('conversion', () {
      test('inDollars converts correctly', () {
        const money = Money(1599);
        expect(money.inDollars, closeTo(15.99, 0.001));
      });

      test('format with default symbol', () {
        const money = Money(1599);
        expect(money.format(), '\$15.99');
      });

      test('format with custom symbol', () {
        const money = Money(5000);
        expect(money.format(symbol: 'SYP '), 'SYP 50.00');
      });

      test('format zero', () {
        const money = Money(0);
        expect(money.format(), '\$0.00');
      });
    });

    group('arithmetic', () {
      test('addition', () {
        const a = Money(1000);
        const b = Money(500);
        expect((a + b).amountInCents, 1500);
      });

      test('subtraction', () {
        const a = Money(1000);
        const b = Money(300);
        expect((a - b).amountInCents, 700);
      });

      test('multiplication by integer', () {
        const a = Money(100);
        expect((a * 3).amountInCents, 300);
      });

      test('multiplication by double', () {
        const a = Money(10000);
        expect((a * 0.15).amountInCents, 1500);
      });

      test('subtraction can go negative (no clamp)', () {
        const a = Money(100);
        const b = Money(200);
        expect((a - b).amountInCents, -100);
      });
    });

    group('equality', () {
      test('equal amounts are equal', () {
        const a = Money(1500);
        const b = Money(1500);
        expect(a, equals(b));
      });

      test('different amounts are not equal', () {
        const a = Money(1500);
        const b = Money(2000);
        expect(a, isNot(equals(b)));
      });

      test('same hashCode for equal amounts', () {
        const a = Money(1500);
        const b = Money(1500);
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('serialization', () {
      test('toMap', () {
        const money = Money(1500);
        expect(money.toMap(), {'amountInCents': 1500});
      });

      test('fromMap', () {
        final money = Money.fromMap({'amountInCents': 2500});
        expect(money.amountInCents, 2500);
      });

      test('fromMap with missing key defaults to 0', () {
        final money = Money.fromMap({});
        expect(money.amountInCents, 0);
      });

      test('roundtrip toMap/fromMap', () {
        const original = Money(4299);
        final restored = Money.fromMap(original.toMap());
        expect(restored, equals(original));
      });
    });
  });
}
