import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums/order_status.dart';
import '../models/order_model.dart';
import '../utils/result.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  DocumentReference<Map<String, dynamic>> _orderRef(String orderId) =>
      _orders.doc(orderId);

  Stream<List<OrderModelEx>> watchIncomingOrders(String restaurantId) =>
      _orders
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', whereIn: [
            OrderStatus.pending.value,
            OrderStatus.accepted.value,
            OrderStatus.preparing.value,
            OrderStatus.readyForDriver.value,
          ])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(OrderModelEx.fromFirestore).toList());

  Stream<List<OrderModelEx>> watchRestaurantOrders(String restaurantId, {
    OrderStatus? status,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> q = _orders
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (status != null) {
      q = _orders
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }
    return q.snapshots().map((snap) => snap.docs.map(OrderModelEx.fromFirestore).toList());
  }

  Stream<List<OrderModelEx>> watchOrdersByCustomer(String customerId, {int limit = 30}) =>
      _orders
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map(OrderModelEx.fromFirestore).toList());

  Stream<OrderModelEx?> watchOrderById(String orderId) =>
      _orderRef(orderId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return OrderModelEx.fromFirestore(doc);
      });

  Stream<List<OrderModelEx>> watchDriverOrders(String driverId) =>
      _orders
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: [
            OrderStatus.readyForDriver.value,
            OrderStatus.pickedUp.value,
          ])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(OrderModelEx.fromFirestore).toList());

  Stream<List<OrderModelEx>> watchAllOrders({OrderStatus? status, int limit = 100}) {
    Query<Map<String, dynamic>> q;
    if (status != null) {
      q = _orders
          .where('status', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    } else {
      q = _orders.orderBy('createdAt', descending: true).limit(limit);
    }
    return q.snapshots().map((snap) => snap.docs.map(OrderModelEx.fromFirestore).toList());
  }

  Future<OrderModelEx?> getOrder(String orderId) async {
    try {
      final doc = await _orderRef(orderId).get();
      if (!doc.exists) return null;
      return OrderModelEx.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Future<List<OrderModelEx>> getOrdersByRestaurant(String restaurantId, {
    int limit = 20,
    OrderStatus? status,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _orders
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (status != null) {
        q = _orders
            .where('restaurantId', isEqualTo: restaurantId)
            .where('status', isEqualTo: status.value)
            .orderBy('createdAt', descending: true)
            .limit(limit);
      }
      final snap = await q.get();
      return snap.docs.map(OrderModelEx.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Result<OrderModelEx>> placeOrder(OrderModelEx order) async {
    try {
      final id = _uuid.v4();
      final ref = _orderRef(id);
      final data = <String, dynamic>{
        ...order.toFirestore(),
        'status': OrderStatus.pending.value,
        'statusMetrics': {
          'placed': FieldValue.serverTimestamp(),
        },
        'statusHistory': [
          {
            'status': OrderStatus.pending.value,
            'timestamp': Timestamp.now(),
            'actorId': order.customerId ?? 'guest',
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await ref.set(data);
      final doc = await ref.get();
      return Success(OrderModelEx.fromFirestore(doc));
    } catch (e) {
      return Failure('Could not place order. Please try again.', error: e);
    }
  }

  Future<Result<void>> transitionStatus(String orderId, OrderStatus newStatus, String actorId, {String? note}) async {
    try {
      await _firestore.runTransaction((txn) async {
        final ref = _orderRef(orderId);
        final snap = await txn.get(ref);
        if (!snap.exists) throw _OrderException('Order not found.');
        final currentStatusStr = (snap.data()!['status'] as String?) ?? '';
        final currentStatus = OrderStatus.fromValue(currentStatusStr);
        if (!_isValidTransition(currentStatus, newStatus)) {
          throw _OrderException(
            'Cannot move order from ${currentStatus.value} \u2192 ${newStatus.value}.',
          );
        }
        final statusKey = newStatus.value;
        final historyEntry = <String, dynamic>{
          'status': statusKey,
          'timestamp': Timestamp.now(),
          'actorId': actorId,
          if (note != null) 'note': note,
        };
        final updateData = <String, dynamic>{
          'status': statusKey,
          'statusMetrics.$statusKey': FieldValue.serverTimestamp(),
          'statusHistory': FieldValue.arrayUnion([historyEntry]),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        switch (newStatus) {
          case OrderStatus.accepted:
            updateData['acceptedAt'] = FieldValue.serverTimestamp();
          case OrderStatus.delivered:
            updateData['deliveredAt'] = FieldValue.serverTimestamp();
          case OrderStatus.cancelled:
            updateData['cancelledAt'] = FieldValue.serverTimestamp();
          default:
            break;
        }
        txn.update(ref, updateData);
      });
      return const Success(null);
    } on _OrderException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Status update failed. Please try again.', error: e);
    }
  }

  Future<Result<void>> rejectOrder(String orderId, String actorId, {String? reason}) =>
      transitionStatus(orderId, OrderStatus.cancelled, actorId, note: reason ?? 'Rejected by restaurant');

  Future<Result<void>> assignDriver(String orderId, {required String driverId, required String driverName}) async {
    try {
      await _firestore.runTransaction((txn) async {
        final ref = _orderRef(orderId);
        final snap = await txn.get(ref);
        if (!snap.exists) throw _OrderException('Order not found.');
        final currentStatus = OrderStatus.fromValue((snap.data()!['status'] as String?) ?? '');
        if (currentStatus != OrderStatus.readyForDriver) {
          throw _OrderException(
            'Order must be ready_for_driver before a driver can be assigned. Current: ${currentStatus.value}',
          );
        }
        final newStatus = OrderStatus.pickedUp;
        final historyEntry = <String, dynamic>{
          'status': newStatus.value,
          'timestamp': Timestamp.now(),
          'actorId': driverId,
          'note': 'Picked up by $driverName',
        };
        txn.update(ref, {
          'driverId': driverId,
          'driverName': driverName,
          'status': newStatus.value,
          'statusMetrics.${newStatus.value}': FieldValue.serverTimestamp(),
          'statusHistory': FieldValue.arrayUnion([historyEntry]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return const Success(null);
    } on _OrderException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Could not assign driver.', error: e);
    }
  }

  Future<Result<void>> updateDriverLocation(String orderId, {required double latitude, required double longitude, int? etaMinutes}) async {
    try {
      final data = <String, dynamic>{
        'driverLatitude': latitude,
        'driverLongitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (etaMinutes != null) data['etaMinutes'] = etaMinutes;
      await _orderRef(orderId).update(data);
      return const Success(null);
    } catch (e) {
      return Failure('Could not update location.', error: e);
    }
  }

  Future<Result<void>> cancelOrder(String orderId, String customerId, {String? reason}) async {
    try {
      await _firestore.runTransaction((txn) async {
        final ref = _orderRef(orderId);
        final snap = await txn.get(ref);
        if (!snap.exists) throw _OrderException('Order not found.');
        final currentStatus = OrderStatus.fromValue((snap.data()!['status'] as String?) ?? '');
        if (currentStatus != OrderStatus.pending && currentStatus != OrderStatus.placed) {
          throw _OrderException(
            'Orders can only be cancelled while pending. Current status: ${currentStatus.value}.',
          );
        }
        final historyEntry = <String, dynamic>{
          'status': OrderStatus.cancelled.value,
          'timestamp': Timestamp.now(),
          'actorId': customerId,
          'note': reason ?? 'Cancelled by customer',
        };
        txn.update(ref, {
          'status': OrderStatus.cancelled.value,
          'statusMetrics.cancelled': FieldValue.serverTimestamp(),
          'statusHistory': FieldValue.arrayUnion([historyEntry]),
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': reason ?? 'Cancelled by customer',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return const Success(null);
    } on _OrderException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Could not cancel order.', error: e);
    }
  }

  static const Map<OrderStatus, Set<OrderStatus>> _validTransitions = {
    OrderStatus.pending: {OrderStatus.accepted, OrderStatus.cancelled},
    OrderStatus.placed: {OrderStatus.accepted, OrderStatus.cancelled},
    OrderStatus.accepted: {OrderStatus.preparing, OrderStatus.cancelled},
    OrderStatus.preparing: {OrderStatus.ready, OrderStatus.readyForDriver, OrderStatus.cancelled},
    OrderStatus.ready: {OrderStatus.readyForDriver, OrderStatus.cancelled},
    OrderStatus.readyForDriver: {OrderStatus.dispatched, OrderStatus.pickedUp, OrderStatus.cancelled},
    OrderStatus.dispatched: {OrderStatus.pickedUp, OrderStatus.cancelled},
    OrderStatus.pickedUp: {OrderStatus.delivered, OrderStatus.cancelled},
    OrderStatus.delivered: {OrderStatus.refunded},
    OrderStatus.cancelled: {},
    OrderStatus.refunded: {},
  };

  static bool _isValidTransition(OrderStatus from, OrderStatus to) {
    final allowed = _validTransitions[from] ?? _validTransitions[OrderStatus.placed];
    if (allowed == null) return false;
    return allowed.contains(to);
  }
}

class _OrderException implements Exception {
  final String message;
  const _OrderException(this.message);
}
