import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_templates.dart';

class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendOrderNotification({
    required String orderId,
    required String customerId,
    required String status,
    required String restaurantName,
  }) async {
    final template = NotificationTemplates.forStatus(status, restaurantName);
    await _firestore.collection('notifications').add({
      ...template.toMap(orderId),
      'recipientId': customerId,
      'role': 'customer',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendDriverNotification({
    required String driverId,
    required String orderId,
    required String action,
  }) async {
    final data = NotificationTemplates.driverNotification(action, orderId);
    await _firestore.collection('notifications').add({
      ...data,
      'recipientId': driverId,
      'role': 'driver',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPartnerNotification({
    required String restaurantId,
    required String orderId,
    required String status,
    required String customerName,
  }) async {
    await _firestore.collection('notifications').add({
      'title': 'New Order Update',
      'body': '$customerName\'s order is now $status',
      'type': 'partner_order_update',
      'orderId': orderId,
      'recipientId': restaurantId,
      'role': 'partner',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
