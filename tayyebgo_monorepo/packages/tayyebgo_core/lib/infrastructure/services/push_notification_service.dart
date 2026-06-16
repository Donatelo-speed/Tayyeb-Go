import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_templates.dart';

class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeAndRegister(String userId, String role) async {
    if (kIsWeb) return;
    try {
      final impl = PushNotificationServiceImpl();
      await impl.initialize(userId, role);
    } catch (e) {
      debugPrint('[PushNotification] Error initializing: $e');
    }
  }

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

class PushNotificationServiceImpl {
  Future<void> initialize(String userId, String role) async {
    try {
      final messaging = _FirebaseMessagingWrapper();
      await messaging.initialize();
      final token = await messaging.getToken();
      if (token != null) {
        await _saveFcmToken(userId, token);
      }
      messaging.onTokenRefresh((newToken) {
        _saveFcmToken(userId, newToken);
      });
      debugPrint('[PushNotification] FCM token registered for $userId ($role)');
    } catch (e) {
      debugPrint('[PushNotification] Error: $e');
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveFcmToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('user_devices').doc(userId).set({
        'userId': userId,
        'fcmToken': token,
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[PushNotification] Error saving token: $e');
    }
  }
}

class _FirebaseMessagingWrapper {
  Future<void> initialize() async {}
  Future<String?> getToken() async => null;
  void onTokenRefresh(void Function(String) callback) {}
}
