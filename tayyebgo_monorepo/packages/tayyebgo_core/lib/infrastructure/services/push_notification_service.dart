import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_templates.dart';

class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initializeAndRegister(String userId, String role) async {
    try {
      if (kIsWeb) return;
      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFcmToken(userId, token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _saveFcmToken(userId, newToken);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      debugPrint('[PushNotification] FCM token registered for $userId ($role)');
    } catch (e) {
      debugPrint('[PushNotification] Error initializing: $e');
    }
  }

  Future<void> _saveFcmToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('user_devices').doc(userId).set({
        'userId': userId,
        'fcmToken': token,
        'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        await FirebaseFunctions.instance.httpsCallable('registerFcmToken').call({
          'fcmToken': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('[PushNotification] Error saving token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[PushNotification] Foreground: ${message.notification?.title}');
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[PushNotification] Opened from: ${message.notification?.title}');
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
