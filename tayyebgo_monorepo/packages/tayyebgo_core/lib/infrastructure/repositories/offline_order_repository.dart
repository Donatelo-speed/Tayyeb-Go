import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/pending_operation_type.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../../domain/value_objects/geo_location.dart';
import '../../domain/value_objects/pending_operation.dart';
import '../services/offline_queue.dart';
import '../services/sync_engine.dart';
import 'firebase_order_repository.dart';

class OfflineOrderRepository implements IOrderRepository {
  static final OfflineOrderRepository instance = OfflineOrderRepository._();
  OfflineOrderRepository._();

  FirebaseOrderRepository get _remote =>
      FirebaseOrderRepository.instance;
  OfflineQueue get _queue => OfflineQueue.instance;
  SyncEngine get _sync => SyncEngine.instance;

  @override
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId) =>
      _remote.watchOrdersForRestaurant(restaurantId);

  @override
  Stream<List<Order>> watchOrdersByStatus(List<OrderStatus> statuses) =>
      _remote.watchOrdersByStatus(statuses);

  @override
  Stream<List<Order>> watchOrdersForDriver(String driverId) =>
      _remote.watchOrdersForDriver(driverId);

  @override
  Stream<List<Order>> watchOrdersForCustomer(String customerId) =>
      _remote.watchOrdersForCustomer(customerId);

  @override
  Stream<Order> watchOrder(String orderId) => _remote.watchOrder(orderId);

  @override
  Future<void> transitionOrder({
    required String orderId,
    required OrderStatus newStatus,
    required String actorId,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    final op = PendingOperation(
      id: '${orderId}_${DateTime.now().millisecondsSinceEpoch}',
      type: PendingOperationType.transitionOrder,
      orderId: orderId,
      newStatus: newStatus,
      location:
          latitude != null ? GeoLocation(latitude, longitude ?? 0) : null,
      actorId: actorId,
      createdAt: DateTime.now(),
    );
    await _queue.enqueue(op);
    try {
      await _remote.transitionOrder(
        orderId: orderId,
        newStatus: newStatus,
        actorId: actorId,
        latitude: latitude,
        longitude: longitude,
        note: note,
      );
      await _queue.dequeue(op.id);
    } catch (_) {
      _sync.start();
    }
  }

  @override
  Future<void> rejectOrder({
    required String orderId,
    required String actorId,
    String? reason,
  }) async {
    final op = PendingOperation(
      id: '${orderId}_reject_${DateTime.now().millisecondsSinceEpoch}',
      type: PendingOperationType.rejectOrder,
      orderId: orderId,
      rejectionReason: reason,
      actorId: actorId,
      createdAt: DateTime.now(),
    );
    await _queue.enqueue(op);
    try {
      await _remote.rejectOrder(
        orderId: orderId,
        actorId: actorId,
        reason: reason,
      );
      await _queue.dequeue(op.id);
    } catch (_) {
      _sync.start();
    }
  }
}