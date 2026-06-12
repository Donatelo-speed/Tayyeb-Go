import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../domain/value_objects/geo_location.dart';

class EtaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _googleApiKey;

  EtaService({String? googleApiKey}) : _googleApiKey = googleApiKey;

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
    if (_googleApiKey != null) {
      final googleEta = await _getGoogleDistanceMatrix(origin, destination);
      if (googleEta != null) return googleEta;
    }

    final distanceM = origin.distanceTo(destination);
    final adjustedSpeed = _adjustSpeedForTimeOfDay(speedMps);
    final minutes = (distanceM / (adjustedSpeed * 60)).round();
    return minutes.clamp(1, 120);
  }

  /// Calculate ETA for a multi-stop route.
  Future<int> calculateMultiStopEta({
    required GeoLocation origin,
    required List<GeoLocation> stops,
  }) async {
    int totalMinutes = 0;
    GeoLocation current = origin;

    for (final stop in stops) {
      final eta = await calculateEta(origin: current, destination: stop);
      totalMinutes += eta;
      current = stop;
    }

    return totalMinutes;
  }

  /// Get ETA with preparation time included.
  Future<int> calculateFullEta({
    required GeoLocation driverLocation,
    required GeoLocation restaurantLocation,
    required GeoLocation customerLocation,
    int preparationMinutes = 10,
  }) async {
    final toRestaurant = await calculateEta(
      origin: driverLocation,
      destination: restaurantLocation,
    );
    final toCustomer = await calculateEta(
      origin: restaurantLocation,
      destination: customerLocation,
    );
    return toRestaurant + preparationMinutes + toCustomer;
  }

  /// Predict ETA based on historical data for this time slot.
  Future<int> predictEtaFromHistory({
    required String restaurantId,
    required GeoLocation customerLocation,
  }) async {
    try {
      final now = DateTime.now();
      final hour = now.hour;
      final dow = now.weekday;

      final cutoff = now.subtract(const Duration(days: 28));
      final snap = await _firestore.collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .limit(200)
          .get();

      final matchingEtas = <int>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final orderDate = ts.toDate();
        if (orderDate.weekday == dow && (orderDate.hour - hour).abs() <= 1) {
          final eta = (data['etaMinutes'] as num?)?.toInt();
          if (eta != null && eta > 0) {
            matchingEtas.add(eta);
          }
        }
      }

      if (matchingEtas.isNotEmpty) {
        matchingEtas.sort();
        return matchingEtas[matchingEtas.length ~/ 2];
      }
    } catch (e) {
      // Fallback to distance-based
    }

    return calculateEta(origin: const GeoLocation(0, 0), destination: customerLocation);
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

  Future<int?> _getGoogleDistanceMatrix(GeoLocation origin, GeoLocation destination) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${origin.latitude},${origin.longitude}'
        '&destinations=${destination.latitude},${destination.longitude}'
        '&key=$_googleApiKey'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data['status'] != 'OK') return null;

      final element = data['rows'][0]['elements'][0];
      if (element['status'] != 'OK') return null;

      final durationSec = (element['duration']?['value'] as num?)?.toInt() ?? 0;
      return (durationSec / 60).ceil().clamp(1, 120);
    } catch (e) {
      return null;
    }
  }

  double _adjustSpeedForTimeOfDay(double baseSpeed) {
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9) return baseSpeed * 0.6;
    if (hour >= 11 && hour <= 14) return baseSpeed * 0.7;
    if (hour >= 17 && hour <= 20) return baseSpeed * 0.55;
    if (hour >= 22 || hour <= 5) return baseSpeed * 1.2;
    return baseSpeed;
  }
}
