import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FraudResult {
  final int score;
  final String level;
  final List<String> reasons;
  final bool shouldBlock;
  final bool requiresReview;

  const FraudResult({
    required this.score,
    required this.level,
    required this.reasons,
    required this.shouldBlock,
    required this.requiresReview,
  });

  Map<String, dynamic> toMap() => {
        'score': score,
        'level': level,
        'reasons': reasons,
        'shouldBlock': shouldBlock,
        'requiresReview': requiresReview,
      };
}

class FraudScoringService {
  static final FraudScoringService instance = FraudScoringService._();
  FraudScoringService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<FraudResult> scoreOrder({
    required String customerId,
    required String restaurantId,
    required double totalAmount,
    required String paymentMethod,
    String? promoCode,
  }) async {
    int risk = 0;
    final reasons = <String>[];

    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));

    // 1. Order velocity (last 24h)
    final velocitySnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(last24h))
        .get();
    final orderCount24h = velocitySnap.docs.length;
    if (orderCount24h > 5) {
      risk += 20;
      reasons.add('High order velocity: $orderCount24h orders in last 24h');
    }

    // 2. High value
    if (totalAmount > 50000) {
      risk += 15;
      reasons.add('High value order: $totalAmount SYP');
    }

    // 3. COD on high value
    if (paymentMethod == 'cash' && totalAmount > 30000) {
      risk += 25;
      reasons.add('COD on high value: $totalAmount SYP');
    }

    // 4. Promo abuse (same promo, same customer, last 24h)
    if (promoCode != null) {
      final promoSnap = await _db
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .where('promoCode', isEqualTo: promoCode)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(last24h))
          .get();
      final promoCount = promoSnap.docs.length;
      if (promoCount > 3) {
        risk += 30;
        reasons.add(
            'Promo code abuse: code "$promoCode" used $promoCount times in 24h');
      }
    }

    // 5. New account (< 24h)
    final userSnap =
        await _db.collection('users').doc(customerId).get();
    final createdAt = (userSnap.data()?['createdAt'] as Timestamp?)?.toDate();
    if (createdAt != null && now.difference(createdAt).inHours < 24) {
      risk += 10;
      reasons.add('New account created ${now.difference(createdAt).inHours}h ago');
    }

    // 6. Multiple cancellations (last 7 days)
    final cancelledSnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'cancelled')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(last7d))
        .get();
    final cancelCount = cancelledSnap.docs.length;
    if (cancelCount > 2) {
      risk += 20;
      reasons.add('$cancelCount cancellations in last 7 days');
    }

    // Clamp score
    final score = risk.clamp(0, 100);

    final level = switch (score) {
      > 80 => 'critical',
      > 60 => 'high',
      >= 30 => 'medium',
      _ => 'low',
    };

    final result = FraudResult(
      score: score,
      level: level,
      reasons: reasons,
      shouldBlock: score > 80,
      requiresReview: score > 60,
    );

    debugPrint(
        '[FraudScoring] customerId=$customerId score=$score level=$level '
        'block=${result.shouldBlock} review=${result.requiresReview} '
        'reasons=$reasons');

    // Audit trail
    await _db.collection('fraud_scores').add({
      'customerId': customerId,
      'restaurantId': restaurantId,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'promoCode': promoCode,
      ...result.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return result;
  }
}
