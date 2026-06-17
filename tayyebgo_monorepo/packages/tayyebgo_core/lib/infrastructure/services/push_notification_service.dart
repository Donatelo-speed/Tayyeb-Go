import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_templates.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  String? _currentToken;
  String? _userId;

  /// Backward-compatible initializer called by AuthProvider.
  Future<void> initializeAndRegister(String userId, String role) async {
    await initialize(userId: userId, role: role);
  }

  /// Initialize Firebase Messaging, request permission, and store the token.
  Future<void> initialize({required String userId, required String role}) async {
    if (kIsWeb) return;
    _userId = userId;
    try {
      await requestPermission();
      final token = await getToken();
      if (token != null) {
        await _saveFcmToken(userId, token, role);
      }
      _messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _saveFcmToken(userId, newToken, role);
      });
      FirebaseMessaging.onMessage.listen(_messageController.add);
      FirebaseMessaging.onMessageOpenedApp.listen(_messageController.add);
      debugPrint('[PushNotification] Initialized for $userId ($role)');
    } catch (e) {
      debugPrint('[PushNotification] Init error: $e');
    }
  }

  /// Returns the current FCM token.
  Future<String?> getToken() async {
    _currentToken = await _messaging.getToken();
    return _currentToken;
  }

  /// Request notification permissions from the user.
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );
    debugPrint('[PushNotification] Permission: ${settings.authorizationStatus}');
    return settings;
  }

  /// Subscribe to a topic for broadcast notifications.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[PushNotification] Subscribed to $topic');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[PushNotification] Unsubscribed from $topic');
  }

  /// Store the FCM token under users/{userId}/deviceTokens/{tokenId}.
  Future<void> _saveFcmToken(String userId, String token, String role) async {
    try {
      final deviceTokensRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens');

      final existing = await deviceTokensRef
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await deviceTokensRef.add({
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : 'ios',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await existing.docs.first.reference.update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[PushNotification] Error saving token: $e');
    }
  }

  /// Send a push notification to a single user via Cloud Functions.
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('push_queue').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[PushNotification] Queued for $userId: $title');
      return true;
    } catch (e) {
      debugPrint('[PushNotification] Error queuing: $e');
      return false;
    }
  }

  /// Send a bulk notification to multiple users (marketing blaster).
  Future<int> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    int sent = 0;
    final batch = _firestore.batch();
    final collRef = _firestore.collection('push_queue');

    for (final uid in userIds) {
      batch.set(collRef.doc(), {
        'userId': uid,
        'title': title,
        'body': body,
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      sent++;
    }

    try {
      await batch.commit();
      debugPrint('[PushNotification] Bulk queued $sent notifications');
    } catch (e) {
      debugPrint('[PushNotification] Bulk error: $e');
      sent = 0;
    }
    return sent;
  }

  /// Send order status notification.
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
    await sendNotification(
      userId: customerId,
      title: template.title,
      body: template.body,
      data: {'type': 'order_update', 'orderId': orderId, 'status': status},
    );
  }

  /// Send notification to a driver.
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
    await sendNotification(
      userId: driverId,
      title: data['title'] as String,
      body: data['body'] as String,
      data: {'type': data['type'], 'orderId': orderId},
    );
  }

  /// Send notification to a restaurant partner.
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
    await sendNotification(
      userId: restaurantId,
      title: 'New Order Update',
      body: '$customerName\'s order is now $status',
      data: {'type': 'order_update', 'orderId': orderId, 'status': status},
    );
  }

  void dispose() {
    _messageController.close();
  }
}
