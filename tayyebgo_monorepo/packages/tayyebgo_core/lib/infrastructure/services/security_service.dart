import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RateLimitEntry {
  final String userId;
  final String action;
  final int count;
  final DateTime windowStart;

  const RateLimitEntry({
    required this.userId,
    required this.action,
    required this.count,
    required this.windowStart,
  });
}

class SecurityService {
  static final SecurityService instance = SecurityService._();
  SecurityService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<String, int> _rateLimits = {
    'order_create': 10,
    'order_cancel': 5,
    'promo_apply': 3,
    'support_ticket': 5,
    'anything_request': 5,
    'login_attempt': 10,
    'otp_request': 5,
  };

  static const Duration _windowDuration = Duration(hours: 1);

  Future<bool> checkRateLimit({
    required String userId,
    required String action,
  }) async {
    final limit = _rateLimits[action] ?? 20;
    final windowStart = DateTime.now().subtract(_windowDuration);

    final snap = await _db
        .collection('rate_limits')
        .where('userId', isEqualTo: userId)
        .where('action', isEqualTo: action)
        .where('timestamp',
            isGreaterThan: Timestamp.fromDate(windowStart))
        .get();

    if (snap.docs.length >= limit) {
      debugPrint('[Security] Rate limit exceeded: $userId/$action');
      await _logSecurityEvent('rate_limit_exceeded', userId, {
        'action': action,
        'count': snap.docs.length,
        'limit': limit,
      });
      return false;
    }

    await _db.collection('rate_limits').add({
      'userId': userId,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<void> logAuditEvent({
    required String actorId,
    required String actorRole,
    required String action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    await _db.collection('audit_logs').add({
      'actorId': actorId,
      'actorRole': actorRole,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> validateAdminAction({
    required String adminId,
    required String action,
    String? resourceType,
    String? resourceId,
  }) async {
    final userDoc = await _db.collection('users').doc(adminId).get();
    final role = userDoc.data()?['role'] as String? ?? '';
    if (role != 'superAdmin' && role != 'admin') {
      throw Exception('Unauthorized: $role cannot perform $action');
    }

    await logAuditEvent(
      actorId: adminId,
      actorRole: role,
      action: action,
      targetType: resourceType,
      targetId: resourceId,
    );
  }

  Future<void> detectSuspiciousActivity(String userId) async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    final ordersSnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
        .get();

    if (ordersSnap.docs.length > 10) {
      await _logSecurityEvent('suspicious_velocity', userId, {
        'ordersInHour': ordersSnap.docs.length,
      });
    }

    final cancelsSnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .where('status', isEqualTo: 'cancelled')
        .where('createdAt',
            isGreaterThan: Timestamp.fromDate(now.subtract(const Duration(days: 1))))
        .get();

    if (cancelsSnap.docs.length > 5) {
      await _logSecurityEvent('suspicious_cancellations', userId, {
        'cancelsInDay': cancelsSnap.docs.length,
      });
    }
  }

  Future<void> _logSecurityEvent(
    String event,
    String userId,
    Map<String, dynamic> details,
  ) async {
    try {
      await _db.collection('activity_log').add({
        'event': event,
        'userId': userId,
        'details': details,
        'severity': 'warning',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Security] Error logging event: $e');
    }
  }

  Future<Map<String, dynamic>> getSecurityOverview() async {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));

    final rateLimitSnap = await _db
        .collection('rate_limits')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(last24h))
        .get();

    final auditSnap = await _db
        .collection('audit_logs')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(last24h))
        .get();

    final suspiciousSnap = await _db
        .collection('activity_log')
        .where('event', whereIn: [
      'rate_limit_exceeded',
      'suspicious_velocity',
      'suspicious_cancellations',
    ])
        .where('timestamp', isGreaterThan: Timestamp.fromDate(last24h))
        .get();

    return {
      'rateLimitHits': rateLimitSnap.docs.length,
      'auditEvents': auditSnap.docs.length,
      'suspiciousActivities': suspiciousSnap.docs.length,
      'last24Hours': true,
    };
  }
}
