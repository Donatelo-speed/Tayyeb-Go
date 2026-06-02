import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../../infrastructure/services/order_state_machine.dart';

class FirebaseOrderRepository implements IOrderRepository {
  static final FirebaseOrderRepository instance = FirebaseOrderRepository._();
  FirebaseOrderRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _orders => _firestore.collection('Orders');

  @override
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId) =>
      _orders
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Order.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList());

  @override
  Stream<List<Order>> watchOrdersByStatus(List<OrderStatus> statuses) =>
      _orders
          .where('status', whereIn: statuses.map((s) => s.value).toList())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Order.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList());

  @override
  Stream<List<Order>> watchOrdersForDriver(String driverId) => _orders
      .where('driverId', isEqualTo: driverId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Order.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Stream<List<Order>> watchOrdersForCustomer(String customerId) => _orders
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Order.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Stream<Order> watchOrder(String orderId) => _orders
      .doc(orderId)
      .snapshots()
      .map((d) => Order.fromMap(d.data() as Map<String, dynamic>, d.id));

  @override
  Future<void> transitionOrder({
    required String orderId,
    required OrderStatus newStatus,
    required String actorId,
    double? latitude,
    double? longitude,
    String? note,
  }) =>
      OrderStateMachine.transition(
        orderId: orderId,
        newStatus: newStatus,
        actorId: actorId,
        latitude: latitude,
        longitude: longitude,
        note: note,
      );

  @override
  Future<void> rejectOrder({
    required String orderId,
    required String actorId,
    String? reason,
  }) =>
      OrderStateMachine.rejectOrder(
        orderId: orderId,
        actorId: actorId,
        reason: reason,
      );
}
