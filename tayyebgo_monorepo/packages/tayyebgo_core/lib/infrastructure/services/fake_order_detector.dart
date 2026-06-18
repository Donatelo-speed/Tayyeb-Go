import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DetectionResult {
  const DetectionResult({
    required this.suspicious,
    required this.flags,
    required this.riskLevel,
    required this.details,
  });

  final bool suspicious;
  final List<String> flags;
  final String riskLevel;
  final Map<String, dynamic> details;

  Map<String, dynamic> toMap() => {
        'suspicious': suspicious,
        'flags': flags,
        'riskLevel': riskLevel,
        'details': details,
      };
}

class FakeOrderDetector {
  static final FakeOrderDetector instance = FakeOrderDetector._();
  FakeOrderDetector._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DetectionResult> analyzeOrder({
    required String customerId,
    required String restaurantId,
    required double totalAmount,
    required String paymentMethod,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    final flags = <String>[];
    final details = <String, dynamic>{};
    final now = DateTime.now();

    // 1. Rapid fire: >3 orders from same customer in 5 minutes = HIGH
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));
    final rapidSnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(fiveMinAgo))
        .get();
    final rapidCount = rapidSnap.docs.length;
    details['ordersInLast5Min'] = rapidCount;
    if (rapidCount > 3) {
      flags.add('RAPID_FIRE');
      if (kDebugMode) debugPrint(
          '[FakeOrderDetector] RAPID_FIRE: $customerId placed $rapidCount orders in 5min');
    }

    // 2. Address mismatch: delivery >10km from usual addresses = MEDIUM
    final usualAddressesSnap = await _db
        .collection('customers')
        .doc(customerId)
        .collection('saved_addresses')
        .get();
    final deliveryLat = deliveryAddress['lat'] as double?;
    final deliveryLng = deliveryAddress['lng'] as double?;
    if (deliveryLat != null && deliveryLng != null) {
      double minDistance = double.infinity;
      for (final doc in usualAddressesSnap.docs) {
        final addrLat = doc.data()['lat'] as double?;
        final addrLng = doc.data()['lng'] as double?;
        if (addrLat != null && addrLng != null) {
          final dist = _haversineKm(deliveryLat, deliveryLng, addrLat, addrLng);
          if (dist < minDistance) minDistance = dist;
        }
      }
      details['distanceToNearestAddress'] =
          minDistance == double.infinity ? null : minDistance;
      if (minDistance > 10) {
        flags.add('ADDRESS_MISMATCH');
        if (kDebugMode) debugPrint(
            '[FakeOrderDetector] ADDRESS_MISMATCH: $customerId delivery ${minDistance.toStringAsFixed(1)}km from usual');
      }
    }

    // 3. Pattern repeat: same items >5 times in 24h = MEDIUM
    final twentyFourH = now.subtract(const Duration(hours: 24));
    final recentOrdersSnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(twentyFourH))
        .get();
    final itemCounts = <String, int>{};
    for (final doc in recentOrdersSnap.docs) {
      final items = doc.data()['items'] as List<dynamic>? ?? [];
      final normalized =
          items.map((i) => (i['name'] as String? ?? '').toLowerCase()).toList()
            ..sort();
      final key = normalized.join('|');
      if (key.isNotEmpty) {
        itemCounts[key] = (itemCounts[key] ?? 0) + 1;
      }
    }
    details['orderPatterns24h'] = itemCounts;
    final maxRepeat =
        itemCounts.values.isEmpty ? 0 : itemCounts.values.reduce((a, b) => a > b ? a : b);
    if (maxRepeat > 5) {
      flags.add('PATTERN_REPEAT');
      if (kDebugMode) debugPrint(
          '[FakeOrderDetector] PATTERN_REPEAT: $customerId repeated same items $maxRepeat times in 24h');
    }

    // 4. COD cycling: cash order cancelled and reordered >2 times = HIGH
    if (paymentMethod == 'cash') {
      final cancelledSnap = await _db
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .where('paymentMethod', isEqualTo: 'cash')
          .where('status', isEqualTo: 'cancelled')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(twentyFourH))
          .get();
      final cancelledCount = cancelledSnap.docs.length;
      details['cashCancelled24h'] = cancelledCount;
      if (cancelledCount > 2) {
        flags.add('COD_CYCLING');
        if (kDebugMode) debugPrint(
            '[FakeOrderDetector] COD_CYCLING: $customerId cancelled $cancelledCount cash orders in 24h');
      }
    }

    // 5. New account + high value: account <1h old AND totalAmount > 20000 SYP = MEDIUM
    final userSnap =
        await _db.collection('users').doc(customerId).get();
    final createdAt =
        (userSnap.data()?['createdAt'] as Timestamp?)?.toDate();
    details['accountAgeHours'] =
        createdAt != null ? now.difference(createdAt).inMinutes / 60.0 : null;
    if (createdAt != null && now.difference(createdAt).inHours < 1) {
      if (totalAmount > 20000) {
        flags.add('NEW_ACCOUNT_HIGH_VALUE');
        if (kDebugMode) debugPrint(
            '[FakeOrderDetector] NEW_ACCOUNT_HIGH_VALUE: $customerId account ${(now.difference(createdAt).inMinutes)}min old, amount $totalAmount SYP');
      }
    }

    // 6. Multiple accounts same address: >3 accounts ordering to same address in 24h = HIGH
    final normalizedAddress = _normalizeAddress(deliveryAddress);
    details['normalizedAddress'] = normalizedAddress;
    if (normalizedAddress.isNotEmpty) {
      final sameAddressSnap = await _db
          .collection('orders')
          .where('normalizedDeliveryAddress', isEqualTo: normalizedAddress)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(twentyFourH))
          .get();
      final uniqueCustomers = sameAddressSnap.docs
          .map((d) => d.data()['customerId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      details['accountsSameAddress24h'] = uniqueCustomers.length;
      if (uniqueCustomers.length > 3) {
        flags.add('MULTI_ACCOUNT_SAME_ADDRESS');
        if (kDebugMode) debugPrint(
            '[FakeOrderDetector] MULTI_ACCOUNT_SAME_ADDRESS: $normalizedAddress used by ${uniqueCustomers.length} accounts in 24h');
      }
    }

    // Determine risk level
    String riskLevel;
    if (flags.contains('RAPID_FIRE') ||
        flags.contains('COD_CYCLING') ||
        flags.contains('MULTI_ACCOUNT_SAME_ADDRESS')) {
      riskLevel = 'high';
    } else if (flags.isNotEmpty) {
      riskLevel = 'medium';
    } else {
      // Check if low-risk heuristics apply (e.g. slightly unusual patterns)
      final riskScore = _computeLowRiskScore(
        rapidCount: rapidCount,
        totalAmount: totalAmount,
        accountAgeHours: details['accountAgeHours'] as double?,
      );
      if (riskScore >= 2) {
        riskLevel = 'low';
      } else {
        riskLevel = 'none';
      }
    }

    details['riskScore'] = _computeLowRiskScore(
      rapidCount: rapidCount,
      totalAmount: totalAmount,
      accountAgeHours: details['accountAgeHours'] as double?,
    );

    final result = DetectionResult(
      suspicious: flags.isNotEmpty,
      flags: flags,
      riskLevel: riskLevel,
      details: details,
    );

    if (kDebugMode) debugPrint(
        '[FakeOrderDetector] customerId=$customerId restaurant=$restaurantId '
        'suspicious=${result.suspicious} risk=$riskLevel flags=$flags');

    return result;
  }

  Future<void> flagOrder({
    required String orderId,
    required DetectionResult result,
  }) async {
    try {
      await _db.collection('order_flags').add({
        'orderId': orderId,
        'flags': result.flags,
        'riskLevel': result.riskLevel,
        'details': result.details,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) debugPrint(
          '[FakeOrderDetector] Flagged order=$orderId risk=${result.riskLevel}');
    } catch (e) {
      if (kDebugMode) debugPrint('[FakeOrderDetector] Failed to flag order $orderId: $e');
    }
  }

  Future<int> getCustomerRiskScore(String customerId) async {
    try {
      final flagsSnap = await _db
          .collection('order_flags')
          .where('customerId', isEqualTo: customerId)
          .get();

      if (flagsSnap.docs.isEmpty) return 0;

      int score = 0;
      final now = DateTime.now();

      for (final doc in flagsSnap.docs) {
        final data = doc.data();
        // ignore: unused_local_variable
        final riskLevel = data['riskLevel'] as String? ?? 'none';
        final createdAt =
            (data['createdAt'] as Timestamp?)?.toDate() ?? now;
        final hoursSince = now.difference(createdAt).inHours;

        // Decay: flags older than 30 days contribute nothing
        if (hoursSince > 720) continue;

        // Weight by recency: full weight <7d, halved <14d, quarter <30d
        double weight = 1.0;
        if (hoursSince > 336) {
          weight = 0.25;
        } else if (hoursSince > 168) {
          weight = 0.5;
        }

        final flags = List<String>.from(data['flags'] as List<dynamic>? ?? []);
        for (final flag in flags) {
          switch (flag) {
            case 'RAPID_FIRE':
              score += (20 * weight).round();
            case 'COD_CYCLING':
              score += (25 * weight).round();
            case 'MULTI_ACCOUNT_SAME_ADDRESS':
              score += (30 * weight).round();
            case 'ADDRESS_MISMATCH':
              score += (10 * weight).round();
            case 'PATTERN_REPEAT':
              score += (10 * weight).round();
            case 'NEW_ACCOUNT_HIGH_VALUE':
              score += (10 * weight).round();
          }
        }
      }

      final clampedScore = score.clamp(0, 100);
      if (kDebugMode) debugPrint(
          '[FakeOrderDetector] Risk score for $customerId = $clampedScore');
      return clampedScore;
    } catch (e) {
      if (kDebugMode) debugPrint('[FakeOrderDetector] Failed to get risk score: $e');
      return 0;
    }
  }

  int _computeLowRiskScore({
    required int rapidCount,
    required double totalAmount,
    double? accountAgeHours,
  }) {
    int score = 0;
    if (rapidCount >= 2) score++;
    if (totalAmount > 15000) score++;
    if (accountAgeHours != null && accountAgeHours < 3) score++;
    return score;
  }

  String _normalizeAddress(Map<String, dynamic> address) {
    final street =
        (address['street'] as String? ?? '').toLowerCase().trim();
    final city =
        (address['city'] as String? ?? '').toLowerCase().trim();
    final district =
        (address['district'] as String? ?? '').toLowerCase().trim();
    final parts = [street, city, district].where((p) => p.isNotEmpty).toList();
    return parts.join('|');
  }

  double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180.0;
}
