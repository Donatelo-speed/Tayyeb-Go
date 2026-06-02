import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/dispatch_request.dart';
import '../../domain/entities/driver.dart';
import '../../domain/services/i_auto_dispatcher.dart';
import '../../domain/value_objects/geo_location.dart';
import '../../src/models/vendor.dart';
import '../repositories/firebase_driver_repository.dart';
import 'driver_scorer.dart';

class AutoDispatcher implements IAutoDispatcher {
  static final AutoDispatcher instance = AutoDispatcher._();
  AutoDispatcher._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseDriverRepository get _driverRepo =>
      FirebaseDriverRepository.instance;
  DriverScorer get _scorer => DriverScorer.instance;

  @override
  Future<void> findAndAssignDriver(
      String dispatchRequestId, String branchId) async {
    final doc = await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .get();
    if (!doc.exists) throw Exception('Dispatch request not found');
    final data = doc.data()!;
    if (data['status'] != 'pending') return;

    final storeId = data['storeId'] as String? ?? branchId;
    final storeDoc = await _firestore.collection('Restaurants').doc(storeId).get();
    final storeData = storeDoc.data() ?? {};

    final deliveryMode = DeliveryMode.fromString(
        storeData['deliveryMode'] as String?);
    final allowFallback = storeData['allowPlatformFallback'] as bool? ?? true;
    final fallbackDelay = (storeData['fallbackDelaySeconds'] as num?)?.toInt() ?? 30;

    final pickup = GeoLocation(
      (data['pickupLat'] as num?)?.toDouble() ?? 0,
      (data['pickupLon'] as num?)?.toDouble() ?? 0,
    );
    final dropoff = GeoLocation(
      (data['dropoffLat'] as num?)?.toDouble() ?? 0,
      (data['dropoffLon'] as num?)?.toDouble() ?? 0,
    );

    await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .update({
      'deliveryMode': deliveryMode.value,
      'status': 'scoring',
      'scoredAt': FieldValue.serverTimestamp(),
    });

    if (deliveryMode.usesStoreDrivers) {
      final assigned = await _tryAssignStoreDrivers(
        dispatchRequestId: dispatchRequestId,
        storeId: storeId,
        pickup: pickup,
        dropoff: dropoff,
      );
      if (assigned) return;

      if (deliveryMode == DeliveryMode.storeOnly || !allowFallback) {
        await _markUnassigned(dispatchRequestId);
        return;
      }

      await _waitFallback(fallbackDelay, dispatchRequestId);

      final stillPending = await _isStillPending(dispatchRequestId);
      if (!stillPending) return;
    }

    if (deliveryMode.usesPlatformDrivers || (deliveryMode == DeliveryMode.storeOnly && allowFallback)) {
      final overloaded = await _arePlatformDriversOverloaded();
      if (overloaded) {
        await _markOverloaded(dispatchRequestId);
        return;
      }

      final assigned = await _tryAssignPlatformDrivers(
        dispatchRequestId: dispatchRequestId,
        pickup: pickup,
        dropoff: dropoff,
      );
      if (assigned) return;
    }

    await _markUnassigned(dispatchRequestId);
  }

  Future<bool> _tryAssignStoreDrivers({
    required String dispatchRequestId,
    required String storeId,
    required GeoLocation pickup,
    required GeoLocation dropoff,
  }) async {
    final drivers = await _driverRepo.watchOnlineByStore(storeId).first;
    if (drivers.isEmpty) return false;

    if (_isOverloaded(drivers)) return false;

    return _scoreAndAssign(
      dispatchRequestId: dispatchRequestId,
      drivers: drivers,
      pickup: pickup,
      dropoff: dropoff,
    );
  }

  Future<bool> _tryAssignPlatformDrivers({
    required String dispatchRequestId,
    required GeoLocation pickup,
    required GeoLocation dropoff,
  }) async {
    final drivers = await _driverRepo.watchOnlinePlatformDrivers().first;
    if (drivers.isEmpty) return false;

    if (_isOverloaded(drivers)) return false;

    return _scoreAndAssign(
      dispatchRequestId: dispatchRequestId,
      drivers: drivers,
      pickup: pickup,
      dropoff: dropoff,
    );
  }

  bool _isOverloaded(List<Driver> drivers) {
    final activeCount = drivers.where((d) => d.activeDeliveries >= 3).length;
    final totalOnline = drivers.length;
    if (totalOnline == 0) return true;
    return (activeCount / totalOnline) > 0.8;
  }

  Future<bool> _arePlatformDriversOverloaded() async {
    final drivers = await _driverRepo.watchOnlinePlatformDrivers().first;
    return _isOverloaded(drivers);
  }

  Future<bool> _scoreAndAssign({
    required String dispatchRequestId,
    required List<Driver> drivers,
    required GeoLocation pickup,
    required GeoLocation dropoff,
  }) async {
    final scores = await _scorer.scoreDrivers(
      availableDrivers: drivers,
      pickupLocation: pickup,
      dropoffLocation: dropoff,
    );
    if (scores.isEmpty) return false;

    final candidateJson = scores.map((s) => s.toJson()).toList();

    await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .update({
      'candidateScores': candidateJson,
      'status': 'scoring',
    });

    final best = scores.first;
    return _firestore.runTransaction((txn) async {
      final snap = await txn.get(
          _firestore.collection('dispatch_requests').doc(dispatchRequestId));
      if (!snap.exists ||
          (snap.data()?['status'] as String? ?? '') != 'scoring') {
        return false;
      }
      txn.update(snap.reference, {
        'status': 'assigned',
        'assignedDriverId': best.driverId,
        'driverType': best.driverType,
        'assignedAt': FieldValue.serverTimestamp(),
        'score': best.score,
        'etaMinutes': best.etaMinutes,
        'distanceKm': best.distanceKm,
      });
      _firestore.collection('Users').doc(best.driverId).update({
        'currentOrderId': dispatchRequestId,
        'activeDeliveries': FieldValue.increment(1),
      }).catchError((_) {});
      return true;
    }).then((result) => result);
  }

  Future<void> _waitFallback(int seconds, String dispatchRequestId) async {
    await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .update({
      'status': 'fallback_waiting',
      'fallbackDelay': seconds,
      'fallbackStartedAt': FieldValue.serverTimestamp(),
    });

    await Future.delayed(Duration(seconds: seconds));
  }

  Future<bool> _isStillPending(String dispatchRequestId) async {
    final doc = await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .get();
    if (!doc.exists) return false;
    final status = doc.data()?['status'] as String? ?? '';
    return status == 'fallback_waiting' || status == 'pending';
  }

  Future<void> _markUnassigned(String dispatchRequestId) async {
    await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .update({
      'status': 'unassigned',
      'unassignedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markOverloaded(String dispatchRequestId) async {
    await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .update({
      'status': 'overloaded',
      'overloadedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<DispatchRequest> watchDispatchRequest(String orderId) =>
      _firestore
          .collection('dispatch_requests')
          .where('orderId', isEqualTo: orderId)
          .snapshots()
          .map((snap) {
        if (snap.docs.isEmpty) {
          throw Exception('No dispatch request for order $orderId');
        }
        final doc = snap.docs.first;
        return DispatchRequest.fromMap(doc.data(), doc.id);
      });
}
