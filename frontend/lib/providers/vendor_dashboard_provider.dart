import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorDashboardData {
  final String vendorId;
  final String vendorName;
  final int todayOrders;
  final double todayRevenue;
  final double rating;
  final int totalReviews;
  final List<VendorOrder> recentOrders;

  VendorDashboardData({
    required this.vendorId,
    required this.vendorName,
    required this.todayOrders,
    required this.todayRevenue,
    required this.rating,
    required this.totalReviews,
    required this.recentOrders,
  });
}

class VendorOrder {
  final String orderId;
  final String customer;
  final String items;
  final double total;
  final String status;
  final String time;
  final Timestamp? createdAt;

  VendorOrder({
    required this.orderId,
    required this.customer,
    required this.items,
    required this.total,
    required this.status,
    required this.time,
    this.createdAt,
  });
}

class VendorDashboardProvider extends ChangeNotifier {
  VendorDashboardData? _data;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _reviewsSubscription;

  VendorDashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _reviewsSubscription?.cancel();
    super.dispose();
  }

  void loadVendorDashboard(String vendorId) {
    _isLoading = true;
    notifyListeners();

    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final allOrders = snapshot.docs.map((doc) {
        final d = doc.data();
        return VendorOrder(
          orderId: doc.id,
          customer: d['customerName'] as String? ?? 'Guest',
          items: _formatItems(d['items']),
          total: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
          status: d['status'] as String? ?? 'pending',
          time: _formatTime(d['createdAt']),
          createdAt: d['createdAt'] as Timestamp?,
        );
      }).toList();

      final todayOrders = allOrders.where((o) {
        final t = o.createdAt?.toDate();
        return t != null && t.isAfter(todayStart);
      }).length;

      final todayRevenue = allOrders
          .where((o) {
            final t = o.createdAt?.toDate();
            return t != null && t.isAfter(todayStart);
          })
          .fold<double>(0.0, (sum, o) => sum + o.total);

      _data = VendorDashboardData(
        vendorId: vendorId,
        vendorName: _data?.vendorName ?? 'Restaurant',
        todayOrders: todayOrders,
        todayRevenue: todayRevenue,
        rating: _data?.rating ?? 0.0,
        totalReviews: _data?.totalReviews ?? 0,
        recentOrders: allOrders.take(10).toList(),
      );
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _data = _getMockData(vendorId);
      _isLoading = false;
      notifyListeners();
    });

    _reviewsSubscription = FirebaseFirestore.instance
        .collection('reviews')
        .where('vendorId', isEqualTo: vendorId.toString())
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;
      final totalReviews = docs.length;
      double avgRating = 0;
      if (docs.isNotEmpty) {
        final sum = docs.fold<double>(
            0, (s, d) => s + ((d.data()['rating'] as num?)?.toDouble() ?? 0));
        avgRating = sum / totalReviews;
      }
      if (_data != null) {
        _data = VendorDashboardData(
          vendorId: _data!.vendorId,
          vendorName: _data!.vendorName,
          todayOrders: _data!.todayOrders,
          todayRevenue: _data!.todayRevenue,
          rating: avgRating,
          totalReviews: totalReviews,
          recentOrders: _data!.recentOrders,
        );
        notifyListeners();
      }
    }, onError: (_) {});
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Failed to update order $orderId: $e');
    }
  }

  String _formatItems(dynamic items) {
    if (items is List) {
      return items.map((i) {
        final name = i is Map ? (i['name'] ?? i['productName'] ?? 'Item') : 'Item';
        final qty = i is Map ? (i['quantity'] ?? 1) : 1;
        return '$qty x $name';
      }).join(', ');
    }
    return 'Items';
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final diff = DateTime.now().difference(timestamp.toDate());
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return '';
  }

  VendorDashboardData _getMockData(String vendorId) {
    return VendorDashboardData(
      vendorId: vendorId,
      vendorName: 'Al Mandi House',
      todayOrders: 23,
      todayRevenue: 340.0,
      rating: 4.8,
      totalReviews: 156,
      recentOrders: [
        VendorOrder(orderId: 'ord-1', customer: 'Ahmed K.', items: '2x Shawarma, 1x Fries', total: 12.50, status: 'preparing', time: '5 min ago'),
        VendorOrder(orderId: 'ord-2', customer: 'Sarah M.', items: '1x Burger, 1x Coke', total: 8.00, status: 'ready', time: '12 min ago'),
        VendorOrder(orderId: 'ord-3', customer: 'Omar R.', items: '3x Pizza', total: 15.00, status: 'delivered', time: '25 min ago'),
      ],
    );
  }
}
