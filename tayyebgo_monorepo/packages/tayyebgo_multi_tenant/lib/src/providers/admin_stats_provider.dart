import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminStats {
  final int restaurantCount;
  final int userCount;
  final int driverCount;
  final int activeOrders;
  final int deliveredToday;
  final double revenueToday;
  final double pendingPayouts;

  const AdminStats({
    this.restaurantCount = 0,
    this.userCount = 0,
    this.driverCount = 0,
    this.activeOrders = 0,
    this.deliveredToday = 0,
    this.revenueToday = 0.0,
    this.pendingPayouts = 0.0,
  });

  AdminStats copyWith({
    int? restaurantCount,
    int? userCount,
    int? driverCount,
    int? activeOrders,
    int? deliveredToday,
    double? revenueToday,
    double? pendingPayouts,
  }) {
    return AdminStats(
      restaurantCount: restaurantCount ?? this.restaurantCount,
      userCount: userCount ?? this.userCount,
      driverCount: driverCount ?? this.driverCount,
      activeOrders: activeOrders ?? this.activeOrders,
      deliveredToday: deliveredToday ?? this.deliveredToday,
      revenueToday: revenueToday ?? this.revenueToday,
      pendingPayouts: pendingPayouts ?? this.pendingPayouts,
    );
  }
}

class AdminStatsProvider extends ChangeNotifier {
  static AdminStatsProvider? _instance;
  static AdminStatsProvider get instance => _instance!;

  AdminStats _stats = const AdminStats();
  AdminStats get stats => _stats;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<QuerySnapshot>? _restaurantSub;
  StreamSubscription<QuerySnapshot>? _userSub;
  StreamSubscription<QuerySnapshot>? _orderSub;
  StreamSubscription<QuerySnapshot>? _activitySub;

  AdminStatsProvider() {
    _instance = this;
    _startListening();
  }

  void _startListening() {
    _restaurantSub?.cancel();
    _userSub?.cancel();
    _orderSub?.cancel();
    _activitySub?.cancel();

    _restaurantSub = FirebaseFirestore.instance
        .collection('Restaurants')
        .snapshots()
        .listen((snap) {
      _stats = _stats.copyWith(restaurantCount: snap.docs.length);
      _updateIfMounted();
    }, onError: _onError);

    _userSub = FirebaseFirestore.instance
        .collection('Users')
        .snapshots()
        .listen((snap) {
      _stats = _stats.copyWith(
        userCount: snap.docs.length,
        driverCount: snap.docs.where((d) {
          final data = d.data();
          return data['role'] == 'driver';
        }).length,
      );
      _updateIfMounted();
    }, onError: _onError);

    _orderSub = FirebaseFirestore.instance
        .collection('Orders')
        .snapshots()
        .listen((snap) {
      final activeStatuses = ['placed', 'accepted', 'preparing', 'ready', 'readyForDriver'];
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      int deliveredToday = 0;
      double revenueToday = 0.0;
      double pendingPayouts = 0.0;

      for (final doc in snap.docs) {
        final d = doc.data();
        final status = d['status'] as String? ?? '';
        if (status == 'delivered') {
          final ts = d['deliveredAt'];
          if (ts is Timestamp && ts.toDate().isAfter(todayStart)) {
            deliveredToday++;
            revenueToday += (d['totalAmount'] as num?)?.toDouble() ?? 0;
          }
          if (d['payoutStatus'] == 'pending') {
            pendingPayouts += (d['totalAmount'] as num?)?.toDouble() ?? 0;
          }
        }
      }

      _stats = _stats.copyWith(
        activeOrders: snap.docs.where((d) {
          final data = d.data();
          return activeStatuses.contains(data['status']);
        }).length,
        deliveredToday: deliveredToday,
        revenueToday: revenueToday,
        pendingPayouts: pendingPayouts,
      );
      _updateIfMounted();
    }, onError: _onError);

    _activitySub = FirebaseFirestore.instance
        .collection('activity_log')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((_) {}, onError: _onError);

    _loading = false;
    _updateIfMounted();
  }

  void _onError(Object e) {
    _error = e.toString();
    _loading = false;
    _updateIfMounted();
  }

  void _updateIfMounted() {
    try {
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() async {
    _error = null;
    _startListening();
  }

  @override
  void dispose() {
    _restaurantSub?.cancel();
    _userSub?.cancel();
    _orderSub?.cancel();
    _activitySub?.cancel();
    super.dispose();
  }
}
