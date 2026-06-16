import 'dart:async';
import '../../domain/enums/order_status.dart';
import '../../domain/services/i_order_store.dart';
import 'delivery_earnings_service.dart';
import 'firebase_order_store.dart';
import 'push_notification_service.dart';

class OrderStateMachine {
  static const _canonicalPipeline = {
    OrderStatus.placed: [OrderStatus.accepted, OrderStatus.cancelled],
    OrderStatus.pending: [OrderStatus.accepted, OrderStatus.cancelled],
    OrderStatus.accepted: [OrderStatus.preparing, OrderStatus.cancelled],
    OrderStatus.preparing: [OrderStatus.ready, OrderStatus.cancelled],
    OrderStatus.ready: [OrderStatus.readyForDriver, OrderStatus.cancelled],
    OrderStatus.readyForDriver: [OrderStatus.dispatched, OrderStatus.cancelled],
    OrderStatus.dispatched: [OrderStatus.pickedUp, OrderStatus.cancelled],
    OrderStatus.pickedUp: [OrderStatus.delivered, OrderStatus.cancelled],
    OrderStatus.delivered: [OrderStatus.refunded],
    OrderStatus.cancelled: [],
    OrderStatus.refunded: [],
  };

  static bool isValidTransition(OrderStatus from, OrderStatus to) =>
      _canonicalPipeline[from]?.contains(to) ?? false;

  static List<String> timelineLabels() => const [
        'Placed', 'Accepted', 'Preparing', 'Ready', 'On the way', 'Delivered',
      ];

  static ({
    String label,
    bool isCompleted,
    bool isCurrent,
    bool isPending
  }) buildTimeline(OrderStatus currentStatus, int stepIndex) {
    final idx = [
      OrderStatus.placed,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.dispatched,
      OrderStatus.delivered,
    ].indexOf(currentStatus);
    final effectiveIdx = switch (currentStatus) {
      OrderStatus.readyForDriver => idx != -1 ? idx : 3,
      OrderStatus.pickedUp => idx != -1 ? idx : 4,
      _ => idx,
    };
    final labels = timelineLabels();
    final isCompleted = stepIndex < effectiveIdx;
    final isCurrent = stepIndex == effectiveIdx;
    return (
      label: labels[stepIndex],
      isCompleted: isCompleted,
      isCurrent: isCurrent,
      isPending: !isCompleted && !isCurrent,
    );
  }

  static Future<void> transition({
    required String orderId,
    required OrderStatus newStatus,
    required String actorId,
    double? latitude,
    double? longitude,
    String? note,
    IOrderStore? store,
  }) async {
    final s = store ?? FirebaseOrderStore.instance;
    String? customerId;
    String? restaurantName;
    String? driverId;
    double? totalAmount;
    double? deliveryFee;
    double? commissionPercent;
    await s.runTransaction((txn) async {
      final data = await txn.readOrder(orderId);
      if (data == null) throw Exception('Order $orderId not found');
      final currentStatus =
          OrderStatus.fromValue(data['status'] as String? ?? '');

      if (!isValidTransition(currentStatus, newStatus)) {
        throw Exception(
            'Invalid transition: ${currentStatus.value} → ${newStatus.value}');
      }

      final transitionEntry = {
        'from': currentStatus.value,
        'to': newStatus.value,
        'timestamp': DateTime.now().toIso8601String(),
        'actorId': actorId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (note != null) 'note': note,
      };

      final history = List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
      history.add(transitionEntry);

      final updates = <String, dynamic>{
        'status': newStatus.value,
        'statusHistory': history,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      customerId = data['customerId'] as String?;
      restaurantName = data['restaurantName'] as String? ?? 'Restaurant';
      driverId = data['driverId'] as String?;

      switch (newStatus) {
        case OrderStatus.accepted:
          updates['acceptedAt'] = DateTime.now().toIso8601String();
        case OrderStatus.ready:
          updates['readyAt'] = DateTime.now().toIso8601String();
        case OrderStatus.readyForDriver:
          updates['readyForDriverAt'] = DateTime.now().toIso8601String();
        case OrderStatus.dispatched:
          updates['dispatchedAt'] = DateTime.now().toIso8601String();
        case OrderStatus.pickedUp:
          updates['pickedUpAt'] = DateTime.now().toIso8601String();
        case OrderStatus.delivered:
          updates['deliveredAt'] = DateTime.now().toIso8601String();
          totalAmount =
              (data['totalAmount'] as num?)?.toDouble() ?? data['totalAmount'] as double?;
          deliveryFee =
              (data['deliveryFee'] as num?)?.toDouble() ?? data['deliveryFee'] as double?;
          commissionPercent =
              (data['commissionPercent'] as num?)?.toDouble() ?? 15.0;
        default:
      }

      await txn.updateOrder(orderId, updates);
    });

    if (newStatus == OrderStatus.delivered && driverId != null && totalAmount != null) {
      unawaited(Future(() async {
        try {
          await DeliveryEarningsService.instance.creditEarnings(
            driverId: driverId!,
            orderId: orderId,
            totalAmount: totalAmount!,
            deliveryFee: deliveryFee,
            commissionPercent: commissionPercent,
          );
        } catch (_) {}
      }));
    }

    if (customerId != null) {
      try {
        final notif = PushNotificationService();
        await notif.sendOrderNotification(
          orderId: orderId,
          customerId: customerId!,
          status: newStatus.value,
          restaurantName: restaurantName ?? 'Restaurant',
        );
      } catch (_) {}
    }
  }

  static Future<void> rejectOrder({
    required String orderId,
    required String actorId,
    String? reason,
    double? latitude,
    double? longitude,
    IOrderStore? store,
  }) async {
    final s = store ?? FirebaseOrderStore.instance;
    String? customerId;
    String? restaurantName;
    await s.runTransaction((txn) async {
      final data = await txn.readOrder(orderId);
      if (data == null) throw Exception('Order $orderId not found');
      final currentStatus =
          OrderStatus.fromValue(data['status'] as String? ?? '');

      if (!isValidTransition(currentStatus, OrderStatus.cancelled)) {
        throw Exception(
            'Cannot reject order in status: ${currentStatus.value}');
      }

      customerId = data['customerId'] as String?;
      restaurantName = data['restaurantName'] as String? ?? 'Restaurant';

      final history = List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
      history.add({
        'from': currentStatus.value,
        'to': 'cancelled',
        'timestamp': DateTime.now().toIso8601String(),
        'actorId': actorId,
        'note': reason ?? 'Rejected',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });

      await txn.updateOrder(orderId, {
        'status': 'cancelled',
        'statusHistory': history,
        'rejectionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });

    if (customerId != null) {
      try {
        final notif = PushNotificationService();
        await notif.sendOrderNotification(
          orderId: orderId,
          customerId: customerId!,
          status: 'cancelled',
          restaurantName: restaurantName ?? 'Restaurant',
        );
      } catch (_) {}
    }
  }

}
