import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum NotificationChannel { push, sms, whatsapp, email, inApp }

class MultiChannelNotification {
  final String recipientId;
  final String recipientRole;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final List<NotificationChannel> channels;
  final DateTime timestamp;

  const MultiChannelNotification({
    required this.recipientId,
    required this.recipientRole,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.channels = const [NotificationChannel.push, NotificationChannel.inApp],
    required this.timestamp,
  });
}

class MultiChannelNotificationService {
  static final MultiChannelNotificationService instance =
      MultiChannelNotificationService._();
  MultiChannelNotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> send(MultiChannelNotification notification) async {
    for (final channel in notification.channels) {
      switch (channel) {
        case NotificationChannel.push:
          await _sendPush(notification);
          break;
        case NotificationChannel.inApp:
          await _sendInApp(notification);
          break;
        case NotificationChannel.sms:
          await _sendSms(notification);
          break;
        case NotificationChannel.whatsapp:
          await _sendWhatsApp(notification);
          break;
        case NotificationChannel.email:
          await _sendEmail(notification);
          break;
      }
    }
  }

  Future<void> _sendInApp(MultiChannelNotification n) async {
    await _db.collection('notifications').add({
      'recipientId': n.recipientId,
      'role': n.recipientRole,
      'title': n.title,
      'body': n.body,
      'type': n.type,
      'data': n.data ?? {},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendPush(MultiChannelNotification n) async {
    try {
      final userDoc =
          await _db.collection('users').doc(n.recipientId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;

      if (kDebugMode) debugPrint('[Notification] Push to ${n.recipientId}: ${n.title}');
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] Push error: $e');
    }
  }

  Future<void> _sendSms(MultiChannelNotification n) async {
    try {
      final userDoc =
          await _db.collection('users').doc(n.recipientId).get();
      final phone = userDoc.data()?['phone'] as String?;
      if (phone == null || phone.isEmpty) return;

      if (kDebugMode) debugPrint('[Notification] SMS to $phone: ${n.title}');
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] SMS error: $e');
    }
  }

  Future<void> _sendWhatsApp(MultiChannelNotification n) async {
    try {
      final userDoc =
          await _db.collection('users').doc(n.recipientId).get();
      final phone = userDoc.data()?['phone'] as String?;
      if (phone == null || phone.isEmpty) return;

      if (kDebugMode) debugPrint('[Notification] WhatsApp to $phone: ${n.title}');
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] WhatsApp error: $e');
    }
  }

  Future<void> _sendEmail(MultiChannelNotification n) async {
    try {
      final userDoc =
          await _db.collection('users').doc(n.recipientId).get();
      final email = userDoc.data()?['email'] as String?;
      if (email == null || email.isEmpty) return;

      if (kDebugMode) debugPrint('[Notification] Email to $email: ${n.title}');
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] Email error: $e');
    }
  }

  Future<void> sendOrderUpdate({
    required String orderId,
    required String customerId,
    required String status,
    required String restaurantName,
  }) async {
    final templates = {
      'placed': ('Order Placed', 'Your order has been placed successfully'),
      'accepted': ('Order Accepted', '$restaurantName accepted your order'),
      'preparing': ('Preparing', '$restaurantName is preparing your food'),
      'ready': ('Ready', 'Your order is ready for pickup'),
      'ready_for_driver': ('Ready', 'Your order is ready for pickup'),
      'dispatched': ('On the Way', 'Your driver is on the way'),
      'picked_up': ('Picked Up', 'Your driver has picked up your order'),
      'delivered': ('Delivered', 'Your order has been delivered. Enjoy!'),
      'cancelled': ('Cancelled', 'Your order from $restaurantName was cancelled'),
    };

    final (title, body) = templates[status] ?? ('Update', 'Order status updated');

    await send(MultiChannelNotification(
      recipientId: customerId,
      recipientRole: 'customer',
      title: title,
      body: body,
      type: 'order_$status',
      data: {'orderId': orderId},
      channels: [NotificationChannel.push, NotificationChannel.inApp],
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendHighDemandAlert({
    required String driverId,
    required String zoneName,
  }) async {
    await send(MultiChannelNotification(
      recipientId: driverId,
      recipientRole: 'driver',
      title: 'High Demand Near You',
      body: 'High demand in $zoneName. Go online to earn more!',
      type: 'high_demand',
      channels: [NotificationChannel.push, NotificationChannel.inApp],
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendStoreTrendingAlert({
    required String restaurantId,
    required String storeName,
  }) async {
    await send(MultiChannelNotification(
      recipientId: restaurantId,
      recipientRole: 'partner',
      title: 'Your Store is Trending',
      body: '$storeName is trending! Orders are increasing.',
      type: 'store_trending',
      channels: [NotificationChannel.inApp],
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendDriverETAUpdate({
    required String customerId,
    required int etaMinutes,
  }) async {
    await send(MultiChannelNotification(
      recipientId: customerId,
      recipientRole: 'customer',
      title: 'Driver is Nearby',
      body: 'Your driver is $etaMinutes minutes away',
      type: 'driver_eta',
      channels: [NotificationChannel.push],
      timestamp: DateTime.now(),
    ));
  }
}
