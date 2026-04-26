import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });
}

enum NotificationType {
  order,
  promotion,
  system,
  delivery,
}

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Order Delivered! 🎉',
      message: 'Your order #1234 has been delivered successfully.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.order,
    ),
    NotificationModel(
      id: '2',
      title: 'Summer Sale - 50% Off',
      message: 'Limited time offer on all electronics. Shop now!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.promotion,
    ),
  ];

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        timestamp: _notifications[index].timestamp,
        isRead: true,
        type: _notifications[index].type,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications.replaceRange(0, _notifications.length, _notifications.map((n) => NotificationModel(
      id: n.id,
      title: n.title,
      message: n.message,
      timestamp: n.timestamp,
      isRead: true,
      type: n.type,
    )).toList());
    notifyListeners();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}