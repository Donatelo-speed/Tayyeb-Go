import 'package:test/test.dart';
import 'package:tayyebgo_core/src/models/promo_model.dart';

void main() {
  group('PromoModel', () {
    group('isUsable', () {
      test('active promo with no expiry is usable', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
        );
        expect(promo.isUsable, isTrue);
      });

      test('inactive promo is not usable', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: false,
        );
        expect(promo.isUsable, isFalse);
      });

      test('expired promo is not usable', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(promo.isUsable, isFalse);
      });

      test('promo at usage limit is not usable', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
          usageLimit: 100,
          usageCount: 100,
        );
        expect(promo.isUsable, isFalse);
      });

      test('promo below usage limit is usable', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
          usageLimit: 100,
          usageCount: 50,
        );
        expect(promo.isUsable, isTrue);
      });
    });

    group('computeDiscount - percentage promo', () {
      test('10% off on 10000 subtotal', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 10,
          isActive: true,
        );
        expect(promo.computeDiscount(10000), 1000);
      });

      test('5% off on 20000 subtotal', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 5,
          isActive: true,
        );
        expect(promo.computeDiscount(20000), 1000);
      });

      test('respects max discount cap', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 50,
          maxDiscountAmount: 500,
          isActive: true,
        );
        // 50% of 2000 = 1000, but capped at 500
        expect(promo.computeDiscount(2000), 500);
      });

      test('uncapped when maxDiscountAmount is 0', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 50,
          maxDiscountAmount: 0,
          isActive: true,
        );
        expect(promo.computeDiscount(2000), 1000);
      });

      test('discount never exceeds subtotal', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 100,
          isActive: true,
        );
        expect(promo.computeDiscount(100), 100);
      });
    });

    group('computeDiscount - flat promo', () {
      test('flat 500 off on 10000 subtotal', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.flat,
          value: 500,
          isActive: true,
        );
        expect(promo.computeDiscount(10000), 500);
      });

      test('flat discount capped at subtotal', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.flat,
          value: 5000,
          isActive: true,
        );
        expect(promo.computeDiscount(1000), 1000);
      });
    });

    group('computeDiscount - min order requirement', () {
      test('returns 0 when subtotal below minOrderAmount', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 10,
          minOrderAmount: 10000,
          isActive: true,
        );
        expect(promo.computeDiscount(5000), 0);
      });

      test('applies discount when subtotal meets minOrderAmount', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 10,
          minOrderAmount: 10000,
          isActive: true,
        );
        expect(promo.computeDiscount(10000), 1000);
      });

      test('applies discount when subtotal exceeds minOrderAmount', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 10,
          minOrderAmount: 5000,
          isActive: true,
        );
        expect(promo.computeDiscount(10000), 1000);
      });
    });

    group('computeDiscount - inactive/expired', () {
      test('returns 0 for inactive promo', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 10,
          isActive: false,
        );
        expect(promo.computeDiscount(10000), 0);
      });

      test('returns 0 for expired promo', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          type: PromoType.percentage,
          value: 10,
          isActive: true,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(promo.computeDiscount(10000), 0);
      });
    });

    group('validate', () {
      test('returns null for valid promo', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
        );
        expect(promo.validate(10000), isNull);
      });

      test('returns error for inactive promo', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: false,
        );
        expect(promo.validate(10000), isNotNull);
      });

      test('returns error for expired promo', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(promo.validate(10000), isNotNull);
      });

      test('returns error when below min order', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          minOrderAmount: 10000,
          isActive: true,
        );
        expect(promo.validate(5000), isNotNull);
      });

      test('returns error at usage limit', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
          usageLimit: 100,
          usageCount: 100,
        );
        expect(promo.validate(10000), isNotNull);
      });
    });

    group('remainingUses', () {
      test('returns -1 for unlimited usage', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          usageLimit: 0,
          usageCount: 0,
        );
        expect(promo.remainingUses, -1);
      });

      test('returns correct remaining count', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          usageLimit: 100,
          usageCount: 30,
        );
        expect(promo.remainingUses, 70);
      });

      test('returns 0 when at limit', () {
        final promo = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          usageLimit: 100,
          usageCount: 100,
        );
        expect(promo.remainingUses, 0);
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = PromoModel(
          id: '1',
          code: 'TEST',
          value: 10,
          isActive: true,
        );
        final copy = original.copyWith(value: 20, isActive: false);
        expect(copy.value, 20);
        expect(copy.isActive, isFalse);
        expect(copy.code, 'TEST'); // unchanged
      });
    });
  });
}
