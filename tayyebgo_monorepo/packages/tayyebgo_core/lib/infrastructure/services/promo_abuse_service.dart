import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PromoCheckResult {
  const PromoCheckResult({
    required this.allowed,
    this.reason,
    required this.usesByUser,
    required this.usesByPhone,
    required this.usesTotal,
  });

  final bool allowed;
  final String? reason;
  final int usesByUser;
  final int usesByPhone;
  final int usesTotal;
}

class PromoAbuseService {
  PromoAbuseService._();
  static final PromoAbuseService instance = PromoAbuseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'promo_usage';

  /// Checks whether a promo usage is allowed based on abuse rules.
  Future<PromoCheckResult> checkPromoUsage({
    required String promoCode,
    required String customerId,
    String? phone,
    String? ipAddress,
  }) async {
    final now = DateTime.now();

    // 1. Per-user limit: max 3 uses of same promo per user per 30 days
    final userQuery = await _db
        .collection(_collection)
        .where('promoCode', isEqualTo: promoCode)
        .where('customerId', isEqualTo: customerId)
        .where('createdAt',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(now.subtract(const Duration(days: 30))))
        .get();

    final usesByUser = userQuery.size;
    if (usesByUser >= 3) {
      return PromoCheckResult(
        allowed: false,
        reason: 'Per-user limit exceeded (max 3 uses per 30 days)',
        usesByUser: usesByUser,
        usesByPhone: 0,
        usesTotal: 0,
      );
    }

    // 2. Per-phone limit: max 5 uses across all accounts with same phone per 30 days
    int usesByPhone = 0;
    if (phone != null && phone.isNotEmpty) {
      final phoneQuery = await _db
          .collection(_collection)
          .where('promoCode', isEqualTo: promoCode)
          .where('phone', isEqualTo: phone)
          .where('createdAt',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(now.subtract(const Duration(days: 30))))
          .get();

      usesByPhone = phoneQuery.size;
      if (usesByPhone >= 5) {
        return PromoCheckResult(
          allowed: false,
          reason: 'Per-phone limit exceeded (max 5 uses per 30 days)',
          usesByUser: usesByUser,
          usesByPhone: usesByPhone,
          usesTotal: 0,
        );
      }
    }

    // 3. Per-IP limit: max 10 uses across all accounts from same IP per 24 hours
    int usesByIp = 0;
    if (ipAddress != null && ipAddress.isNotEmpty) {
      final ipQuery = await _db
          .collection(_collection)
          .where('promoCode', isEqualTo: promoCode)
          .where('ipAddress', isEqualTo: ipAddress)
          .where('createdAt',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(now.subtract(const Duration(hours: 24))))
          .get();

      usesByIp = ipQuery.size;
      if (usesByIp >= 10) {
        return PromoCheckResult(
          allowed: false,
          reason: 'Per-IP limit exceeded (max 10 uses per 24 hours)',
          usesByUser: usesByUser,
          usesByPhone: usesByPhone,
          usesTotal: 0,
        );
      }
    }

    // 4. Global velocity: temp block if promo used >100 times in last 1 hour
    final velocityQuery = await _db
        .collection(_collection)
        .where('promoCode', isEqualTo: promoCode)
        .where('createdAt',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(now.subtract(const Duration(hours: 1))))
        .get();

    final usesTotal = velocityQuery.size;
    if (usesTotal > 100) {
      return PromoCheckResult(
        allowed: false,
        reason: 'Promo temporarily blocked due to high usage (velocity limit)',
        usesByUser: usesByUser,
        usesByPhone: usesByPhone,
        usesTotal: usesTotal,
      );
    }

    return PromoCheckResult(
      allowed: true,
      usesByUser: usesByUser,
      usesByPhone: usesByPhone,
      usesTotal: usesTotal,
    );
  }

  /// Records a promo usage event.
  Future<void> recordPromoUsage({
    required String promoCode,
    required String customerId,
    String? phone,
    String? ipAddress,
  }) async {
    try {
      await _db.collection(_collection).add({
        'promoCode': promoCode,
        'customerId': customerId,
        'phone': phone,
        'ipAddress': ipAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
          'PromoUsageService: recorded usage of $promoCode by $customerId');
    } catch (e) {
      debugPrint('PromoUsageService: failed to record usage - $e');
    }
  }

  /// Returns aggregate stats for a given promo code.
  Future<Map<String, dynamic>> getPromoStats(String promoCode) async {
    try {
      final allQuery = await _db
          .collection(_collection)
          .where('promoCode', isEqualTo: promoCode)
          .get();

      final totalUses = allQuery.size;

      final uniqueUsers =
          allQuery.docs.map((d) => d.data()['customerId'] as String).toSet();

      final uniquePhones = allQuery.docs
          .map((d) => (d.data()['phone'] as String?) ?? '')
          .where((p) => p.isNotEmpty)
          .toSet();

      final todayStart = DateTime.now();
      final todayStartTimestamp = Timestamp.fromDate(
        DateTime(todayStart.year, todayStart.month, todayStart.day),
      );

      final todayQuery = await _db
          .collection(_collection)
          .where('promoCode', isEqualTo: promoCode)
          .where('createdAt', isGreaterThanOrEqualTo: todayStartTimestamp)
          .get();

      return {
        'totalUses': totalUses,
        'uniqueUsers': uniqueUsers.length,
        'uniquePhones': uniquePhones.length,
        'usesToday': todayQuery.size,
      };
    } catch (e) {
      debugPrint('PromoUsageService: failed to get stats - $e');
      return {
        'totalUses': 0,
        'uniqueUsers': 0,
        'uniquePhones': 0,
        'usesToday': 0,
      };
    }
  }
}
