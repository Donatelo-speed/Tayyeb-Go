import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_dispatch_repository.dart';
import '../../infrastructure/services/order_state_machine.dart';
import '../../domain/enums/order_status.dart';

class FirebaseDispatchRepository implements IDispatchRepository {
  static final FirebaseDispatchRepository instance = FirebaseDispatchRepository._();
  FirebaseDispatchRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> watchDispatchesForDriver(String driverId) =>
      _firestore
          .collection('dispatch_requests')
          .where('assignedDriverId', isEqualTo: driverId)
          .snapshots()
          .map((snap) => snap.docs.map((d) {
                final data = d.data();
                data['id'] = d.id;
                return data;
              }).toList());

  @override
  Future<bool> acceptDispatch(String dispatchId, String driverId) async {
    try {
      await _firestore.runTransaction((txn) async {
        final dispatchRef = _firestore.collection('dispatch_requests').doc(dispatchId);
        final snap = await txn.get(dispatchRef);
        if (!snap.exists) throw Exception('Dispatch not found');
        final data = snap.data()!;

        if (data['status'] != 'assigned' && data['status'] != 'awaiting_acceptance') {
          throw Exception('Dispatch already processed');
        }

        txn.update(dispatchRef, {
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          final orderRef = _firestore.collection('orders').doc(orderId);
          final orderSnap = await txn.get(orderRef);
          if (orderSnap.exists) {
            txn.update(orderRef, {
              'driverId': driverId,
              'dispatchedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> rejectDispatch(String dispatchId, String driverId) async {
    try {
      final dispatchRef = _firestore.collection('dispatch_requests').doc(dispatchId);
      Map<String, dynamic>? dispatchData;

      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(dispatchRef);
        if (!snap.exists) return;
        dispatchData = snap.data()!;

        if (dispatchData!['status'] != 'awaiting_acceptance') return;

        txn.update(dispatchRef, {
          'status': 'unassigned',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': driverId,
          'rejectionNote': 'Driver rejected',
          'reassignmentTriggered': true,
        });

        txn.update(
          _firestore.collection('users').doc(driverId),
          {
            'currentOrderId': FieldValue.delete(),
            'activeDeliveries': FieldValue.increment(-1),
          },
        );
      });

      return dispatchData != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> markPickedUp(String dispatchId, String orderId, String driverId) async {
    try {
      await _firestore.runTransaction((txn) async {
        final orderRef = _firestore.collection('orders').doc(orderId);
        final orderSnap = await txn.get(orderRef);
        if (!orderSnap.exists) throw Exception('Order $orderId not found');
        final orderData = orderSnap.data() as Map<String, dynamic>;
        final currentStatus = OrderStatus.fromValue(orderData['status'] as String? ?? '');
        if (!OrderStateMachine.isValidTransition(currentStatus, OrderStatus.pickedUp)) {
          throw Exception('Invalid transition');
        }
        final history = List<Map<String, dynamic>>.from(orderData['statusHistory'] ?? []);
        history.add({
          'from': currentStatus.value,
          'to': OrderStatus.pickedUp.value,
          'timestamp': DateTime.now().toIso8601String(),
          'actorId': driverId,
        });
        txn.update(orderRef, {
          'status': OrderStatus.pickedUp.value,
          'pickedUpAt': DateTime.now().toIso8601String(),
          'statusHistory': history,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        txn.update(
          _firestore.collection('dispatch_requests').doc(dispatchId),
          {'status': 'pickedUp', 'pickedUpAt': FieldValue.serverTimestamp()},
        );
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> completeDelivery(String dispatchId, String orderId, String driverId) async {
    try {
      await _firestore.runTransaction((txn) async {
        final orderRef = _firestore.collection('orders').doc(orderId);
        final orderSnap = await txn.get(orderRef);
        if (!orderSnap.exists) throw Exception('Order $orderId not found');
        final orderData = orderSnap.data() as Map<String, dynamic>;
        final currentStatus = OrderStatus.fromValue(orderData['status'] as String? ?? '');
        if (!OrderStateMachine.isValidTransition(currentStatus, OrderStatus.delivered)) {
          throw Exception('Invalid transition');
        }
        final history = List<Map<String, dynamic>>.from(orderData['statusHistory'] ?? []);
        history.add({
          'from': currentStatus.value,
          'to': OrderStatus.delivered.value,
          'timestamp': DateTime.now().toIso8601String(),
          'actorId': driverId,
        });
        txn.update(orderRef, {
          'status': OrderStatus.delivered.value,
          'deliveredAt': DateTime.now().toIso8601String(),
          'statusHistory': history,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        txn.update(
          _firestore.collection('dispatch_requests').doc(dispatchId),
          {'status': 'delivered', 'deliveredAt': FieldValue.serverTimestamp()},
        );
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
