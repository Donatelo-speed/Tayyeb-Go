import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tayyebgo_core/presentation/theme/app_radius.dart';
import 'package:tayyebgo_core/presentation/theme/app_spacing.dart';
import 'package:tayyebgo_core/presentation/theme/app_motion.dart';

void main() {
  group('AppRadius', () {
    test('scale values are in ascending order', () {
      expect(AppRadius.xs, lessThan(AppRadius.sm));
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
      expect(AppRadius.xl, lessThan(AppRadius.xxl));
      expect(AppRadius.xxl, lessThan(AppRadius.xxxl));
    });

    test('brCard uses xl radius (12px)', () {
      expect(AppRadius.brCard, const BorderRadius.all(Radius.circular(12)));
    });

    test('brButton uses md radius (8px)', () {
      expect(AppRadius.brButton, const BorderRadius.all(Radius.circular(8)));
    });

    test('brInput uses sm radius (6px)', () {
      expect(AppRadius.brInput, const BorderRadius.all(Radius.circular(6)));
    });

    test('brChip uses full radius (pill)', () {
      expect(AppRadius.brChip, const BorderRadius.all(Radius.circular(999)));
    });

    test('brAvatar uses full radius (circle)', () {
      expect(AppRadius.brAvatar, const BorderRadius.all(Radius.circular(999)));
    });

    test('brDialog uses xxxl radius (20px)', () {
      expect(AppRadius.brDialog, const BorderRadius.all(Radius.circular(20)));
    });

    test('brBottomSheet has top-only rounding', () {
      final bs = AppRadius.brBottomSheet;
      expect(bs.topLeft, const Radius.circular(20));
      expect(bs.bottomLeft, Radius.zero);
      expect(bs.bottomRight, Radius.zero);
    });

    test('brTopOnly creates asymmetric radius', () {
      final r = AppRadius.brTopOnly(16);
      expect(r.topLeft, const Radius.circular(16));
      expect(r.bottomLeft, Radius.zero);
    });

    test('brBottomOnly creates asymmetric radius', () {
      final r = AppRadius.brBottomOnly(16);
      expect(r.topLeft, Radius.zero);
      expect(r.bottomLeft, const Radius.circular(16));
    });
  });

  group('AppSpacing', () {
    test('scale follows 8pt grid', () {
      expect(AppSpacing.xxs, 4);
      expect(AppSpacing.xs, 8);
      expect(AppSpacing.sm, 12);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
      expect(AppSpacing.xxxl, 64);
    });

    test('screenPadding uses horizontal md (16px)', () {
      expect(AppSpacing.screenPadding, const EdgeInsets.symmetric(horizontal: 16));
    });

    test('cardPadding uses md (16px)', () {
      expect(AppSpacing.cardPadding, const EdgeInsets.all(16));
    });

    test('horizontal padding presets', () {
      expect(AppSpacing.horizontalXs.left, 4);
      expect(AppSpacing.horizontalSm.left, 8);
      expect(AppSpacing.horizontalMd.left, 16);
      expect(AppSpacing.horizontalLg.left, 24);
      expect(AppSpacing.horizontalXl.left, 32);
    });
  });

  group('AppMotion', () {
    test('duration scale exists and is ascending', () {
      expect(AppMotion.instant.inMilliseconds, 80);
      expect(AppMotion.fast.inMilliseconds, 120);
      expect(AppMotion.normal.inMilliseconds, 200);
      expect(AppMotion.medium.inMilliseconds, 280);
      expect(AppMotion.slow.inMilliseconds, 360);
      expect(AppMotion.lazy.inMilliseconds, 480);
    });

    test('curves exist', () {
      expect(AppMotion.easeOut, isNotNull);
      expect(AppMotion.easeInOut, isNotNull);
      expect(AppMotion.spring, isNotNull);
      expect(AppMotion.decelerate, isNotNull);
      expect(AppMotion.accelerate, isNotNull);
    });

    test('specialty durations alias standard durations', () {
      expect(AppMotion.heroDuration, AppMotion.slow);
      expect(AppMotion.pageTransition, AppMotion.medium);
      expect(AppMotion.bottomSheet, AppMotion.medium);
      expect(AppMotion.dialog, AppMotion.medium);
    });

    test('stagger constants', () {
      expect(AppMotion.staggerDelay.inMilliseconds, 60);
      expect(AppMotion.staggerCount, 8);
    });

    test('ticker durations', () {
      expect(AppMotion.shimmerDuration.inMilliseconds, 1500);
      expect(AppMotion.pulseDuration.inMilliseconds, 1200);
      expect(AppMotion.spinDuration.inMilliseconds, 1000);
    });
  });
}
