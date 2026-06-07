import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/enums/order_status.dart';
import '../../infrastructure/services/auto_dispatcher.dart';
import '../../infrastructure/services/order_state_machine.dart';
import '../../infrastructure/services/delivery_earnings_service.dart';
import '../../infrastructure/services/push_notification_service.dart';

class DispatchProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assignedDispatches = [];
  List<Map<String, dynamic>> _activeDeliveries = [];
  bool _isLoading = false;
  String? _error;
  String? _driverId;
  StreamSubscription<QuerySnapshot>? _dispatchSub;

  List<Map<String, dynamic>> get assignedDispatches => _assignedDispatches;
  List<Map<String, dynamic>> get activeDeliveries => _activeDeliveries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void startListening(String driverId) {
    if (_driverId == driverId && _dispatchSub != null) return;
    _driverId = driverId;
    _dispatchSub?.cancel();
    _subscribe(driverId);
  }

  void _subscribe(String driverId, {int retryCount = 0}) {
    _dispatchSub = FirebaseFirestore.instance
        .collection('dispatch_requests')
        .where('assignedDriverId', isEqualTo: driverId)
        .snapshots()
        .listen((snap) {
      _isLoading = false;
      _assignedDispatches = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .where((d) =>
              d['status'] == 'assigned' || d['status'] == 'awaiting_acceptance')
          .toList();
      _activeDeliveries = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .where((d) =>
              ['accepted', 'enRoute', 'pickedUp'].contains(d['status']))
          .toList();
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (_driverId == driverId && retryCount < 5) {
        Future.delayed(Duration(seconds: (retryCount + 1) * 2), () {
          if (_driverId == driverId) {
            _subscribe(driverId, retryCount: retryCount + 1);
          }
        });
      }
    });
  }

  Future<bool> acceptDispatch(String dispatchId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final dispatchRef =
            FirebaseFirestore.instance.collection('dispatch_requests').doc(dispatchId);
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
          final orderRef =
              FirebaseFirestore.instance.collection('orders').doc(orderId);
          final orderSnap = await txn.get(orderRef);
          if (orderSnap.exists) {
            txn.update(orderRef, {
              'driverId': _driverId,
              'dispatchedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      final notif = PushNotificationService();
      await notif.sendDriverNotification(
        driverId: _driverId ?? '',
        orderId: dispatchId,
        action: 'accepted',
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectDispatch(String dispatchId) async {
    try {
      final dispatchRef =
          FirebaseFirestore.instance.collection('dispatch_requests').doc(dispatchId);
      Map<String, dynamic>? dispatchData;

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(dispatchRef);
        if (!snap.exists) return;
        dispatchData = snap.data()!;

        if (dispatchData!['status'] != 'awaiting_acceptance') {
          return;
        }

        txn.update(dispatchRef, {
          'status': 'unassigned',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': _driverId,
          'rejectionNote': 'Driver rejected',
          'reassignmentTriggered': true,
        });

        if (_driverId != null) {
          txn.update(
            FirebaseFirestore.instance.collection('users').doc(_driverId),
            {
              'currentOrderId': FieldValue.delete(),
              'activeDeliveries': FieldValue.increment(-1),
            },
          );
        }
      });

      if (dispatchData != null) {
        unawaited(_triggerReassignment(dispatchId, dispatchData!));
      }

      return dispatchData != null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _triggerReassignment(
      String dispatchId, Map<String, dynamic> data) async {
    final restaurantId = data['restaurantId'] as String? ?? '';
    final branchId = data['branchId'] as String? ?? data['restaurantId'] as String? ?? '';
    try {
      await AutoDispatcher.instance.reassignDriver(
        dispatchRequestId: dispatchId,
        branchId: branchId.isNotEmpty ? branchId : restaurantId,
        excludeDriverId: _driverId,
      );
    } catch (_) {}
  }

  Future<bool> markPickedUp(String dispatchId, String orderId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final orderRef =
            FirebaseFirestore.instance.collection('orders').doc(orderId);
        final orderSnap = await txn.get(orderRef);
        if (!orderSnap.exists) throw Exception('Order $orderId not found');
        final orderData = orderSnap.data() as Map<String, dynamic>;
        final currentStatus =
            OrderStatus.fromValue(orderData['status'] as String? ?? '');
        if (!OrderStateMachine.isValidTransition(
            currentStatus, OrderStatus.pickedUp)) {
          throw Exception(
              'Invalid transition: ${currentStatus.value} -> ${OrderStatus.pickedUp.value}');
        }
        final history =
            List<Map<String, dynamic>>.from(orderData['statusHistory'] ?? []);
        history.add({
          'from': currentStatus.value,
          'to': OrderStatus.pickedUp.value,
          'timestamp': DateTime.now().toIso8601String(),
          'actorId': _driverId ?? '',
        });
        txn.update(orderRef, {
          'status': OrderStatus.pickedUp.value,
          'pickedUpAt': DateTime.now().toIso8601String(),
          'statusHistory': history,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        txn.update(
          FirebaseFirestore.instance
              .collection('dispatch_requests')
              .doc(dispatchId),
          {
            'status': 'pickedUp',
            'pickedUpAt': FieldValue.serverTimestamp(),
          },
        );
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeDelivery(String dispatchId, String orderId) async {
    try {
      String? driverId;
      double? totalAmount;
      double? deliveryFee;
      double? commissionPercent;
      String? customerId;
      String? restaurantName;

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final orderRef =
            FirebaseFirestore.instance.collection('orders').doc(orderId);
        final orderSnap = await txn.get(orderRef);
        if (!orderSnap.exists) throw Exception('Order $orderId not found');
        final orderData = orderSnap.data() as Map<String, dynamic>;
        final currentStatus =
            OrderStatus.fromValue(orderData['status'] as String? ?? '');
        if (!OrderStateMachine.isValidTransition(
            currentStatus, OrderStatus.delivered)) {
          throw Exception(
              'Invalid transition: ${currentStatus.value} -> ${OrderStatus.delivered.value}');
        }
        final history =
            List<Map<String, dynamic>>.from(orderData['statusHistory'] ?? []);
        history.add({
          'from': currentStatus.value,
          'to': OrderStatus.delivered.value,
          'timestamp': DateTime.now().toIso8601String(),
          'actorId': _driverId ?? '',
        });
        totalAmount =
            (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        deliveryFee =
            (orderData['deliveryFee'] as num?)?.toDouble();
        commissionPercent =
            (orderData['commissionPercent'] as num?)?.toDouble() ?? 15.0;
        driverId = orderData['driverId'] as String?;
        customerId = orderData['customerId'] as String?;
        restaurantName =
            orderData['restaurantName'] as String? ?? 'Restaurant';
        final paymentMethod =
            orderData['paymentMethodType'] as String? ?? '';
        final isCod = paymentMethod == 'sham_cash' || paymentMethod == 'cash';
        txn.update(orderRef, {
          'status': OrderStatus.delivered.value,
          'deliveredAt': DateTime.now().toIso8601String(),
          'statusHistory': history,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        txn.update(
          FirebaseFirestore.instance
              .collection('dispatch_requests')
              .doc(dispatchId),
          {
            'status': 'delivered',
            'deliveredAt': FieldValue.serverTimestamp(),
            if (isCod) 'codCollectedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      if (driverId != null && totalAmount != null && totalAmount! > 0) {
        unawaited(DeliveryEarningsService.instance.creditEarnings(
          driverId: driverId!,
          orderId: orderId,
          totalAmount: totalAmount!,
          deliveryFee: deliveryFee,
          commissionPercent: commissionPercent,
        ));
      }

      if (customerId != null) {
        final notif = PushNotificationService();
        await notif.sendOrderNotification(
          orderId: orderId,
          customerId: customerId!,
          status: OrderStatus.delivered.value,
          restaurantName: restaurantName ?? 'Restaurant',
        );
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String? getOrderIdForDispatch(String dispatchId) {
    final found = [
      ..._assignedDispatches,
      ..._activeDeliveries,
    ].firstWhere(
      (d) => d['id'] == dispatchId,
      orElse: () => <String, dynamic>{},
    );
    return found['orderId'] as String?;
  }

  void stopListening() {
    _dispatchSub?.cancel();
    _dispatchSub = null;
  }

  void clear() {
    stopListening();
    _assignedDispatches = [];
    _activeDeliveries = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
