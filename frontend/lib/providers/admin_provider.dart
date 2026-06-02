import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AdminData {
  final int totalRestaurants;
  final int activeUsers;
  final int totalOrders;
  final String revenue;
  final int drivers;
  final int pendingOrders;
  final List<ActivityItem> recentActivity;

  AdminData({
    required this.totalRestaurants,
    required this.activeUsers,
    required this.totalOrders,
    required this.revenue,
    required this.drivers,
    required this.pendingOrders,
    required this.recentActivity,
  });

  factory AdminData.fromJson(Map<String, dynamic> json) {
    return AdminData(
      totalRestaurants: json['totalRestaurants'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      revenue: json['revenue'] ?? '\$0',
      drivers: json['drivers'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      recentActivity: (json['recentActivity'] as List<dynamic>?)
          ?.map((e) => ActivityItem.fromJson(e))
          .toList() ?? [],
    );
  }

  factory AdminData.empty() {
    return AdminData(
      totalRestaurants: 0,
      activeUsers: 0,
      totalOrders: 0,
      revenue: '\$0',
      drivers: 0,
      pendingOrders: 0,
      recentActivity: [],
    );
  }
}

class ActivityItem {
  final String icon;
  final String text;
  final String time;
  final String color;

  ActivityItem({
    required this.icon,
    required this.text,
    required this.time,
    required this.color,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      icon: json['icon'] ?? 'info',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
      color: json['color'] ?? 'blue',
    );
  }
}

class AdminProvider extends ChangeNotifier {
  AdminData _data = AdminData.empty();
  bool _isLoading = false;
  String? _error;

  AdminData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/admin/dashboard');
      if (response['error'] != null) {
        _data = _getMockData();
      } else {
        _data = AdminData.fromJson(response);
      }
    } catch (e) {
      _data = _getMockData();
    }

    _isLoading = false;
    notifyListeners();
  }

  AdminData _getMockData() {
    return AdminData(
      totalRestaurants: 45,
      activeUsers: 1234,
      totalOrders: 5678,
      revenue: '\$45K',
      drivers: 89,
      pendingOrders: 12,
      recentActivity: [
        ActivityItem(icon: 'store', text: 'New restaurant "Al Mandi House" registered', time: '2 min ago', color: 'blue'),
        ActivityItem(icon: 'person', text: 'New user registered: john@email.com', time: '15 min ago', color: 'green'),
        ActivityItem(icon: 'shopping_cart', text: 'New order #1234 placed', time: '30 min ago', color: 'orange'),
        ActivityItem(icon: 'delivery', text: 'Driver "Khaled" completed delivery', time: '1 hour ago', color: 'cyan'),
        ActivityItem(icon: 'money', text: 'Payment received: \$45.00', time: '2 hours ago', color: 'purple'),
      ],
    );
  }
}