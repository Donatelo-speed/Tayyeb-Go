import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSafetyService {
  static final DriverSafetyService instance = DriverSafetyService._();
  DriverSafetyService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> reportDriverOffline(String driverId, String orderId) async {
    final doc = await _db
        .collection('dispatch_requests')
        .doc(orderId)
        .get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final status = data['status'] as String? ?? '';

    if (status == 'assigned' || status == 'accepted') {
      final lastUpdate = (data['updatedAt'] as Timestamp?)?.toDate();
      if (lastUpdate != null &&
          DateTime.now().difference(lastUpdate).inMinutes > 5) {
        await _db.collection('dispatch_requests').doc(orderId).update({
          'status': 'unassigned',
          'reassignReason': 'driver_inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _db.collection('activity_log').add({
          'event': 'driver_inactive_reassign',
          'driverId': driverId,
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> handleStoreRejection({
    required String orderId,
    required String storeId,
    String? reason,
  }) async {
    await _db.collection('dispatch_requests').doc(orderId).update({
      'status': 'store_rejected',
      'storeRejectionReason': reason ?? 'Store rejected order',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('activity_log').add({
      'event': 'store_rejected_order',
      'storeId': storeId,
      'orderId': orderId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportDeliveryProofIssue({
    required String orderId,
    required String reporterId,
    required String reporterRole,
    required String issue,
  }) async {
    await _db.collection('support_tickets').add({
      'userId': reporterId,
      'userRole': reporterRole,
      'orderId': orderId,
      'category': 'delivery_proof',
      'description': issue,
      'status': 'open',
      'priority': 'high',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportFakeGPS({
    required String driverId,
    required String reportedBy,
    required String evidence,
  }) async {
    await _db.collection('driver_reports').add({
      'driverId': driverId,
      'reportType': 'fake_gps',
      'reportedBy': reportedBy,
      'evidence': evidence,
      'status': 'pending_review',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('activity_log').add({
      'event': 'fake_gps_report',
      'driverId': driverId,
      'reportedBy': reportedBy,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> flagFraudulentOrder({
    required String orderId,
    required String reason,
    required String detectedBy,
  }) async {
    await _db.collection('order_flags').add({
      'orderId': orderId,
      'reason': reason,
      'detectedBy': detectedBy,
      'status': 'pending_review',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchSOSAlerts() {
    return _db
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> sendSOSAlert({
    required String driverId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    await _db.collection('sos_alerts').add({
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'message': message ?? 'Driver SOS',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
