import '../entities/order.dart';
import '../enums/order_status.dart';

abstract class IOrderRepository {
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId);
  Stream<List<Order>> watchOrdersByStatus(List<OrderStatus> statuses);
  Stream<List<Order>> watchOrdersForDriver(String driverId);
  Stream<List<Order>> watchOrdersForCustomer(String customerId);
  Stream<Order> watchOrder(String orderId);

  Future<void> transitionOrder({
    required String orderId,
    required OrderStatus newStatus,
    required String actorId,
    double? latitude,
    double? longitude,
    String? note,
  });

  Future<void> rejectOrder({
    required String orderId,
    required String actorId,
    String? reason,
  });
}
