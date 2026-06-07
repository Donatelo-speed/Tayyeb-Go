import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/driver.dart';
import '../../domain/repositories/i_driver_repository.dart';

/// Single source of truth for driver online state: [users.isOnline].
///
/// Migration note (P5):
/// - The dispatcher reads [users.isOnline] to find available drivers.
/// - The driver dashboard writes [driver_locations.isOnline] for GPS dedup.
/// - Decision: [users.isOnline] is the authoritative online flag.
/// - The dashboard now writes to BOTH collections on toggle.
/// - Future: migrate all reads to [driver_locations.isOnline] once
///   GPS tracking is always-on (background mode). Until then, keep
///   [users.isOnline] as the source for dispatch queries.
class FirebaseDriverRepository implements IDriverRepository {
  static final FirebaseDriverRepository instance = FirebaseDriverRepository._();
  FirebaseDriverRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Query<Map<String, dynamic>> get _baseQuery =>
      _firestore.collection('users').where('role', isEqualTo: 'driver');

  @override
  Stream<List<Driver>> watchAll() => _baseQuery.snapshots().map((s) => s.docs
      .map((d) => Driver.fromMap(d.data(), d.id))
      .toList());

  @override
  Stream<List<Driver>> watchOnline() => _baseQuery
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Driver.fromMap(d.data(), d.id))
          .toList());

  @override
  Stream<List<Driver>> watchOnlineByStore(String storeId) => _firestore
      .collection('users')
      .where('role', isEqualTo: 'driver')
      .where('isOnline', isEqualTo: true)
      .where('driverType', isEqualTo: 'store')
      .where('storeId', isEqualTo: storeId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Driver.fromMap(d.data(), d.id))
          .toList());

  @override
  Stream<List<Driver>> watchOnlinePlatformDrivers() => _firestore
      .collection('users')
      .where('role', isEqualTo: 'driver')
      .where('isOnline', isEqualTo: true)
      .where('driverType', isEqualTo: 'platform')
      .snapshots()
      .map((s) => s.docs
          .map((d) => Driver.fromMap(d.data(), d.id))
          .toList());

  @override
  Future<void> updateLocation(String driverId, double lat, double lng) =>
      _firestore.collection('users').doc(driverId).update({
        'latitude': lat,
        'longitude': lng,
      });

  @override
  Future<void> setOnlineStatus(String driverId, bool online) =>
      _firestore.collection('users').doc(driverId).update({
        'isOnline': online,
      });
}
