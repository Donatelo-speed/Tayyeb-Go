import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/enums/order_status.dart';
import 'push_notification_service.dart';
import 'notification_templates.dart';

class OrderStateMachine {
  static const _canonicalPipeline = {
    OrderStatus.placed: [OrderStatus.accepted, OrderStatus.cancelled],
    OrderStatus.accepted: [OrderStatus.preparing, OrderStatus.cancelled],
    OrderStatus.preparing: [OrderStatus.ready, OrderStatus.cancelled],
    OrderStatus.ready: [OrderStatus.readyForDriver, OrderStatus.cancelled],
    OrderStatus.readyForDriver: [OrderStatus.dispatched, OrderStatus.cancelled],
    OrderStatus.dispatched: [OrderStatus.pickedUp, OrderStatus.cancelled],
    OrderStatus.pickedUp: [OrderStatus.delivered, OrderStatus.cancelled],
    OrderStatus.delivered: [],
    OrderStatus.cancelled: [],
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
    // Map readyForDriver and pickedUp to their visual positions
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
  }) async {
    final ref = FirebaseFirestore.instance.collection('Orders').doc(orderId);
    String? customerId;
    String? restaurantName;
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw Exception('Order $orderId not found');
      final data = snap.data() as Map<String, dynamic>;
      final currentStatus =
          OrderStatus.fromValue(data['status'] as String? ?? '');

      if (!isValidTransition(currentStatus, newStatus)) {
        throw Exception(
            'Invalid transition: ${currentStatus.value} → ${newStatus.value}');
      }

      final transition = {
        'from': currentStatus.value,
        'to': newStatus.value,
        'timestamp': DateTime.now().toIso8601String(),
        'actorId': actorId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (note != null) 'note': note,
      };

      final history = List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
      history.add(transition);

      final updates = <String, dynamic>{
        'status': newStatus.value,
        'statusHistory': history,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      customerId = data['customerId'] as String?;
      restaurantName = data['restaurantName'] as String? ?? 'Restaurant';

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
        default:
      }

      txn.update(ref, updates);
    });

    if (customerId != null) {
      final notif = PushNotificationService();
      await notif.sendOrderNotification(
        orderId: orderId,
        customerId: customerId!,
        status: newStatus.value,
        restaurantName: restaurantName ?? 'Restaurant',
      );
      final template = NotificationTemplates.forStatus(newStatus.value, restaurantName ?? 'Restaurant');
      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          ...template.toMap(orderId),
          'userId': customerId,
          'read': false,
        });
      } catch (_) {}
    }
  }

  static Future<void> rejectOrder({
    required String orderId,
    required String actorId,
    String? reason,
    double? latitude,
    double? longitude,
  }) async {
    final ref = FirebaseFirestore.instance.collection('Orders').doc(orderId);
    String? customerId;
    String? restaurantName;
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw Exception('Order $orderId not found');
      final data = snap.data() as Map<String, dynamic>;
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

      txn.update(ref, {
        'status': 'cancelled',
        'statusHistory': history,
        'rejectionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });

    if (customerId != null) {
      final notif = PushNotificationService();
      await notif.sendOrderNotification(
        orderId: orderId,
        customerId: customerId!,
        status: 'cancelled',
        restaurantName: restaurantName ?? 'Restaurant',
      );
    }
  }

}
