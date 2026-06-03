import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_models.dart';

class AdminProvider extends ChangeNotifier {
  DashboardStats _stats = const DashboardStats();
  List<ActivityLogEntry> _activities = [];
  List<AdminStore> _stores = [];
  List<AdminDriver> _drivers = [];
  List<SupportTicket> _tickets = [];
  PlatformSettings _settings = const PlatformSettings();
  bool _loading = true;
  String? _error;

  StreamSubscription? _statsSub;
  StreamSubscription? _activitySub;
  StreamSubscription? _storesSub;
  StreamSubscription? _driversSub;
  StreamSubscription? _ticketsSub;
  StreamSubscription? _settingsSub;

  DashboardStats get stats => _stats;
  List<ActivityLogEntry> get activities => _activities;
  List<AdminStore> get stores => _stores;
  List<AdminDriver> get drivers => _drivers;
  List<SupportTicket> get tickets => _tickets;
  PlatformSettings get settings => _settings;
  bool get loading => _loading;
  String? get error => _error;

  void init() {
    _startSubscriptions();
  }

  void _startSubscriptions() {
    final db = FirebaseFirestore.instance;

    _statsSub = db.collection('orders').snapshots().listen((s) {
      int active = 0;
      int today = 0;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      for (final d in s.docs) {
        final data = d.data();
        final status = data['status'] as String? ?? '';
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        final created = (data['createdAt'] as Timestamp?)?.toDate();


        if (const ['pending', 'accepted', 'preparing', 'ready_for_driver', 'picked_up'].contains(status)) active++;
        if (created != null && created.isAfter(todayStart)) {
          today++;
          _stats = DashboardStats(
            revenueToday: _stats.revenueToday + amount,
            ordersToday: today,
            activeOrders: active,
            onlineDrivers: _stats.onlineDrivers,
            activeStores: _stats.activeStores,
            newCustomers: _stats.newCustomers,
            pendingRefunds: _stats.pendingRefunds,
            pendingTickets: _stats.pendingTickets,
            pendingDriverApplications: _stats.pendingDriverApplications,
            pendingStoreRequests: _stats.pendingStoreRequests,
            platformHealth: _stats.platformHealth,
          );
        } else {
          _stats = DashboardStats(
            revenueToday: _stats.revenueToday,
            ordersToday: _stats.ordersToday,
            activeOrders: active,
            onlineDrivers: _stats.onlineDrivers,
            activeStores: _stats.activeStores,
            newCustomers: _stats.newCustomers,
            pendingRefunds: _stats.pendingRefunds,
            pendingTickets: _stats.pendingTickets,
            pendingDriverApplications: _stats.pendingDriverApplications,
            pendingStoreRequests: _stats.pendingStoreRequests,
            platformHealth: _stats.platformHealth,
          );
        }
      }
      _loading = false;
      notifyListeners();
    }, onError: (e) { _error = e.toString(); _loading = false; notifyListeners(); });

    _activitySub = db.collection('activity_log').orderBy('timestamp', descending: true).limit(20).snapshots().listen((s) {
      _activities = s.docs.map((d) => ActivityLogEntry.fromFirestore(d)).toList();
      notifyListeners();
    });

    _storesSub = db.collection('restaurants').snapshots().listen((s) {
      _stores = s.docs.map((d) => AdminStore.fromFirestore(d)).toList();
      _stats = DashboardStats(
        revenueToday: _stats.revenueToday,
        ordersToday: _stats.ordersToday,
        activeOrders: _stats.activeOrders,
        onlineDrivers: _stats.onlineDrivers,
        activeStores: _stores.where((s) => s.isOpen && !s.isSuspended).length,
        newCustomers: _stats.newCustomers,
        pendingRefunds: _stats.pendingRefunds,
        pendingTickets: _stats.pendingTickets,
        pendingDriverApplications: _stats.pendingDriverApplications,
        pendingStoreRequests: _stats.pendingStoreRequests,
        platformHealth: _stats.platformHealth,
      );
      notifyListeners();
    });

    _driversSub = db.collection('drivers').snapshots().listen((s) {
      _drivers = s.docs.map((d) => AdminDriver.fromFirestore(d)).toList();
      _stats = DashboardStats(
        revenueToday: _stats.revenueToday,
        ordersToday: _stats.ordersToday,
        activeOrders: _stats.activeOrders,
        onlineDrivers: _drivers.where((d) => d.status == DriverStatus.online).length,
        activeStores: _stats.activeStores,
        newCustomers: _stats.newCustomers,
        pendingRefunds: _stats.pendingRefunds,
        pendingTickets: _stats.pendingTickets,
        pendingDriverApplications: _drivers.where((d) => !d.isVerified).length,
        pendingStoreRequests: _stats.pendingStoreRequests,
        platformHealth: _stats.platformHealth,
      );
      notifyListeners();
    });

    _ticketsSub = db.collection('support_tickets').snapshots().listen((s) {
      _tickets = s.docs.map((d) => SupportTicket.fromFirestore(d)).toList();
      _stats = DashboardStats(
        revenueToday: _stats.revenueToday,
        ordersToday: _stats.ordersToday,
        activeOrders: _stats.activeOrders,
        onlineDrivers: _stats.onlineDrivers,
        activeStores: _stats.activeStores,
        newCustomers: _stats.newCustomers,
        pendingRefunds: _stats.pendingRefunds,
        pendingTickets: _tickets.where((t) => const ['open', 'assigned', 'in_progress'].contains(t.status)).length,
        pendingDriverApplications: _stats.pendingDriverApplications,
        pendingStoreRequests: _stats.pendingStoreRequests,
        platformHealth: _stats.platformHealth,
      );
      notifyListeners();
    });

    _settingsSub = db.collection('platform_settings').doc('main').snapshots().listen((s) {
      if (s.exists) _settings = PlatformSettings.fromFirestore(s);
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _statsSub?.cancel();
      await _activitySub?.cancel();
      await _storesSub?.cancel();
      await _driversSub?.cancel();
      await _ticketsSub?.cancel();
      await _settingsSub?.cancel();
      _startSubscriptions();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    _activitySub?.cancel();
    _storesSub?.cancel();
    _driversSub?.cancel();
    _ticketsSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }
}