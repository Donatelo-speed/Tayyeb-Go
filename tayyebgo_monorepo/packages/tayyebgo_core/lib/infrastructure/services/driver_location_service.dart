import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/value_objects/geohash.dart';
import '../../domain/value_objects/geo_location.dart';

class DriverLocationService {
  static final DriverLocationService instance = DriverLocationService._();
  DriverLocationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;
  String? _driverId;
  DateTime _lastUpdate = DateTime(2000);
  bool _isOnline = false;
  static const Duration _minInterval = Duration(seconds: 5);
  static const Duration _staleThreshold = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(minutes: 2);

  /// Fake GPS detection: maximum allowed speed in m/s (approx 180 km/h)
  static const double _maxAllowedSpeed = 50.0;
  /// Maximum allowed distance jump in meters between consecutive updates
  static const double _maxAllowedJump = 2000.0;
  GeoLocation? _lastKnownPosition;
  DateTime? _lastPositionTime;

  void start(String driverId) {
    _driverId = driverId;
    _isOnline = true;
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isOnline) return;
      Geolocator.getLastKnownPosition().then((pos) {
        if (pos != null) _updateLocation(pos);
      });
    });
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen(_updateLocation);
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _removeStaleEntries());
  }

  void stop() {
    _isOnline = false;
    _positionSub?.cancel();
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    _positionSub = null;
    _heartbeatTimer = null;
    _cleanupTimer = null;
    _driverId = null;
    _lastKnownPosition = null;
    _lastPositionTime = null;
  }

  bool get isRunning => _driverId != null;

  void setOnlineStatus(String driverId, bool online) {
    _isOnline = online;
    _firestore.collection('driver_locations').doc(driverId).set({
      'isOnline': online,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((_) {});
  }

  void forceRefresh(String driverId) {
    if (!_isOnline) return;
    Geolocator.getLastKnownPosition().then((pos) {
      if (pos != null) _updateLocation(pos);
    });
  }

  Future<void> _removeStaleEntries() async {
    final cutoff = DateTime.now().toUtc().subtract(_staleThreshold);
    final stale = await _firestore
        .collection('driver_locations')
        .where('updatedAt', isLessThan: cutoff)
        .get();
    if (stale.docs.isEmpty) return;
    final activeDriverIds = <String>{};
    final activeDispatchSnap = await _firestore
        .collection('dispatch_requests')
        .where('status', whereIn: ['accepted', 'enRoute', 'pickedUp'])
        .get();
    for (final doc in activeDispatchSnap.docs) {
      final driverId = doc.data()['assignedDriverId'] as String?;
      if (driverId != null) activeDriverIds.add(driverId);
    }
    final batch = _firestore.batch();
    for (final doc in stale.docs) {
      if (!activeDriverIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  bool _detectFakeGps(Position pos) {
    final now = DateTime.now();
    final currentPos = GeoLocation(pos.latitude, pos.longitude);

    if (_lastKnownPosition != null && _lastPositionTime != null) {
      final timeDiff = now.difference(_lastPositionTime!).inSeconds;
      if (timeDiff > 0) {
        final distance = _lastKnownPosition!.distanceTo(currentPos);
        final speed = distance / timeDiff;

        /// Check for impossible speed (teleportation)
        if (speed > _maxAllowedSpeed) {
          _flagSuspiciousActivity('Impossible speed detected: ${speed.toStringAsFixed(1)} m/s');
          return true;
        }

        /// Check for large distance jump
        if (distance > _maxAllowedJump) {
          _flagSuspiciousActivity('Distance jump detected: ${distance.toStringAsFixed(0)}m in ${timeDiff}s');
          return true;
        }
      }
    }

    _lastKnownPosition = currentPos;
    _lastPositionTime = now;
    return false;
  }

  void _flagSuspiciousActivity(String reason) {
    final id = _driverId;
    if (id == null) return;

    _firestore.collection('driver_locations').doc(id).update({
      'suspiciousActivity': FieldValue.arrayUnion([
        {
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
    });

    _firestore.collection('activity_log').doc().set({
      'type': 'fake_gps_suspected',
      'driverId': id,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _updateLocation(Position pos) {
    final id = _driverId;
    if (id == null) return;
    if (!_isOnline) return;
    final now = DateTime.now();
    if (now.difference(_lastUpdate) < _minInterval) return;

    /// Fake GPS detection
    if (_detectFakeGps(pos)) return;

    _lastUpdate = now;
    final geohash = Geohash.encode(pos.latitude, pos.longitude, precision: 4);

    _firestore.collection('driver_locations').doc(id).set({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'geohash': geohash,
      'heading': pos.heading,
      'speed': pos.speed,
      'accuracy': pos.accuracy,
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _firestore.collection('users').doc(id).update({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    }).catchError((_) {});
  }
}
