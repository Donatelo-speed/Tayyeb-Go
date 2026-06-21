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

  static const int acceptanceTimeoutSeconds = 45;

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

    // Skip high-risk fraud flagged dispatches — hold for manual review
    if (data['fraudRisk'] == true) return;

    final storeId = data['storeId'] as String? ?? branchId;
    final storeDoc = await _firestore.collection('restaurants').doc(storeId).get();
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

    await _appendStatusHistory(dispatchRequestId, 'pending', 'scoring');
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
    String? excludeDriverId,
  }) async {
    final available = excludeDriverId != null
        ? drivers.where((d) => d.id != excludeDriverId).toList()
        : drivers;
    if (available.isEmpty) return false;

    final scores = await _scorer.scoreDrivers(
      availableDrivers: available,
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
        'status': 'awaiting_acceptance',
        'assignedDriverId': best.driverId,
        'driverType': best.driverType,
        'assignedAt': FieldValue.serverTimestamp(),
        'acceptanceDeadline':
            FieldValue.serverTimestamp(),
        'acceptanceTimeoutSeconds': acceptanceTimeoutSeconds,
        'score': best.score,
        'etaMinutes': best.etaMinutes,
        'distanceKm': best.distanceKm,
      });
      txn.update(_firestore.collection('users').doc(best.driverId), {
        'currentOrderId': dispatchRequestId,
        'activeDeliveries': FieldValue.increment(1),
      });
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
    await _appendStatusHistory(dispatchRequestId, null, 'unassigned');
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

  Future<void> _appendStatusHistory(
      String dispatchRequestId, String? from, String to) async {
    try {
      await _firestore
          .collection('dispatch_requests')
          .doc(dispatchRequestId)
          .update({
        'statusHistory': FieldValue.arrayUnion([
          {
            'from': from ?? '',
            'to': to,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
      });
    } catch (_) {} // Status history update failure is non-critical
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

  Future<void> reassignDriver({
    required String dispatchRequestId,
    required String branchId,
    String? excludeDriverId,
  }) async {
    final doc = await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final status = data['status'] as String? ?? '';

    final validStatuses = ['awaiting_acceptance', 'assigned', 'unassigned', 'scoring', 'timeout'];
    if (!validStatuses.contains(status)) return;

    final storeId = data['storeId'] as String? ?? branchId;
    final pickup = GeoLocation(
      (data['pickupLat'] as num?)?.toDouble() ?? 0,
      (data['pickupLon'] as num?)?.toDouble() ?? 0,
    );
    final dropoff = GeoLocation(
      (data['dropoffLat'] as num?)?.toDouble() ?? 0,
      (data['dropoffLon'] as num?)?.toDouble() ?? 0,
    );

    final skippedDriverIds = List<String>.from(data['skippedDriverIds'] ?? []);
    if (excludeDriverId != null && !skippedDriverIds.contains(excludeDriverId)) {
      skippedDriverIds.add(excludeDriverId);
    }

    await _appendStatusHistory(dispatchRequestId, status, 'reassigning');
    await _firestore
        .collection('dispatch_requests')
        .doc(dispatchRequestId)
        .update({
      'status': 'reassigning',
      'skippedDriverIds': skippedDriverIds,
      'reassignedAt': FieldValue.serverTimestamp(),
    });

    final storeDoc =
        await _firestore.collection('restaurants').doc(storeId).get();
    final storeData = storeDoc.data() ?? {};
    final deliveryMode =
        DeliveryMode.fromString(storeData['deliveryMode'] as String?);
    final allowFallback =
        storeData['allowPlatformFallback'] as bool? ?? true;

    bool assigned = false;

    if (deliveryMode.usesStoreDrivers) {
      final drivers = await _driverRepo.watchOnlineByStore(storeId).first;
      final filtered = drivers
          .where((d) => !skippedDriverIds.contains(d.id))
          .toList();
      if (filtered.isNotEmpty && !_isOverloaded(filtered)) {
        assigned = await _scoreAndAssign(
          dispatchRequestId: dispatchRequestId,
          drivers: filtered,
          pickup: pickup,
          dropoff: dropoff,
          excludeDriverId: excludeDriverId,
        );
      }
      if (!assigned && (deliveryMode == DeliveryMode.storeOnly || !allowFallback)) {
        await _markUnassigned(dispatchRequestId);
        return;
      }
    }

    if (!assigned && (deliveryMode.usesPlatformDrivers ||
        (deliveryMode == DeliveryMode.storeOnly && allowFallback))) {
      final drivers = await _driverRepo.watchOnlinePlatformDrivers().first;
      final filtered = drivers
          .where((d) => !skippedDriverIds.contains(d.id))
          .toList();
      if (filtered.isNotEmpty && !_isOverloaded(filtered)) {
        assigned = await _scoreAndAssign(
          dispatchRequestId: dispatchRequestId,
          drivers: filtered,
          pickup: pickup,
          dropoff: dropoff,
          excludeDriverId: excludeDriverId,
        );
      }
    }

    if (!assigned) {
      await _markUnassigned(dispatchRequestId);
    }
  }

  Future<void> handleDriverOffline(String driverId) async {
    final snapshot = await _firestore
        .collection('dispatch_requests')
        .where('assignedDriverId', isEqualTo: driverId)
        .where('status', whereIn: ['awaiting_acceptance', 'assigned', 'accepted'])
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final branchId = data['restaurantId'] as String? ?? '';
      await _firestore.collection('dispatch_requests').doc(doc.id).update({
        'status': 'unassigned',
        'offlineAt': FieldValue.serverTimestamp(),
        'offlineDriverId': driverId,
      });
      await _firestore.collection('users').doc(driverId).update({
        'currentOrderId': FieldValue.delete(),
        'activeDeliveries': FieldValue.increment(-1),
      }).catchError((_) {});
      unawaited(reassignDriver(
        dispatchRequestId: doc.id,
        branchId: branchId,
        excludeDriverId: driverId,
      ));
    }
  }
}
