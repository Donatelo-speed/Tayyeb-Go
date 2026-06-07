import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/value_objects/geo_location.dart';

class EtaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> watchEtaMinutes({
    required String driverId,
    required GeoLocation destination,
    double speedMps = 8.0,
  }) {
    return _firestore
        .collection('driver_locations')
        .doc(driverId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return -1;
      final d = doc.data() as Map<String, dynamic>;
      final lat = (d['latitude'] as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return -1;
      final origin = GeoLocation(lat, lng);
      final distanceM = origin.distanceTo(destination);
      final minutes = (distanceM / (speedMps * 60)).round();
      return minutes.clamp(1, 120);
    });
  }

  Future<int> calculateEta({
    required GeoLocation origin,
    required GeoLocation destination,
    double speedMps = 8.0,
  }) async {
    final distanceM = origin.distanceTo(destination);
    final minutes = (distanceM / (speedMps * 60)).round();
    return minutes.clamp(1, 120);
  }

  Future<void> updateOrderEta({
    required String orderId,
    required int etaMinutes,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'etaMinutes': etaMinutes,
      'etaUpdatedAt': DateTime.now().toIso8601String(),
    });
  }
}
