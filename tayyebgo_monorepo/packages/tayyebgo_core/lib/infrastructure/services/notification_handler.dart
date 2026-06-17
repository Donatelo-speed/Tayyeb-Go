import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../src/constants/route_names.dart';
import 'push_notification_service.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._();
  factory NotificationHandler() => _instance;
  NotificationHandler._();

  GoRouter? _router;
  String? _currentUserId;
  final PushNotificationService _pushService = PushNotificationService();

  /// Initialize the handler with router and listen for incoming messages.
  void initialize({required GoRouter router, String? userId}) {
    _router = router;
    _currentUserId = userId;
    _listenToMessages();
    debugPrint('[NotificationHandler] Initialized');
  }

  /// Update the current user (e.g. after login/logout).
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  /// Listen to foreground messages and route them.
  void _listenToMessages() {
    _pushService.onMessage.listen(_handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
      _navigateFromData(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessage(message);
        _navigateFromData(message.data);
      }
    });
  }

  /// Process an incoming message — store it, show UI feedback, etc.
  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? data['title'] ?? '';
    final body = message.notification?.body ?? data['body'] ?? '';
    final type = data['type'] ?? 'unknown';

    debugPrint('[NotificationHandler] Received: type=$type title=$title');

    if (_router == null) return;
  }

  /// Route to the appropriate screen based on the notification's data type.
  void _navigateFromData(Map<String, dynamic> data) {
    if (_router == null) return;

    final type = data['type'] as String?;
    final id = data['orderId'] as String? ?? data['id'] as String?;

    switch (type) {
      case 'order_update':
      case 'order_placed':
      case 'order_accepted':
      case 'order_preparing':
      case 'order_ready':
      case 'order_dispatched':
      case 'order_delivered':
      case 'order_cancelled':
      case 'driver_assigned':
        if (id != null) {
          _router!.push(Routes.customerTrackingPath(id));
        } else {
          _router!.push(Routes.customerOrders);
        }
        break;

      case 'driver_new_dispatch':
      case 'driver_pickup_ready':
      case 'driver_update':
        if (id != null) {
          _router!.push(Routes.driverActivePath(id));
        }
        break;

      case 'partner_order_update':
      case 'new_order':
      case 'order_ready_for_driver':
        _router!.push(Routes.partnerCashier);
        break;

      case 'promotion':
      case 'promo':
        _router!.push('/explore');
        break;

      case 'wallet':
      case 'wallet_topup':
      case 'wallet_credit':
        _router!.push('/wallet');
        break;

      case 'loyalty':
      case 'loyalty_reward':
        _router!.push('/loyalty');
        break;

      case 'support':
      case 'ticket_reply':
        _router!.push('/help-support');
        break;

      default:
        _router!.push(Routes.customerRoot);
    }
  }

  /// Manually trigger navigation from notification data (e.g. from a tap handler).
  void navigateFromNotification(Map<String, dynamic> data) {
    _navigateFromData(data);
  }

  void dispose() {
    _router = null;
    _currentUserId = null;
  }
}
