import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/offline_sync_service.dart';
import '../services/sync_queue.dart';

class OfflineSyncProvider extends ChangeNotifier {
  final OfflineSyncService _service = OfflineSyncService();
  StreamSubscription<bool>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingActionsCount = 0;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingActionsCount => _pendingActionsCount;
  bool get hasPendingActions => _pendingActionsCount > 0;

  Future<void> initialize() async {
    await _service.initialize();

    _isOnline = _service.isOnline;
    _pendingActionsCount = _service.pendingActionsCount;
    notifyListeners();

    _connectivitySubscription = _service.connectivityStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    });
  }

  Future<void> cacheMenu(String restaurantId, Map<String, dynamic> menu) async {
    await _service.cacheMenu(restaurantId, menu);
  }

  Future<Map<String, dynamic>?> getCachedMenu(String restaurantId) async {
    return await _service.getCachedMenu(restaurantId);
  }

  Future<void> cacheCart(List<Map<String, dynamic>> items) async {
    await _service.cacheCart(items);
  }

  Future<List<Map<String, dynamic>>?> getCachedCart() async {
    return await _service.getCachedCart();
  }

  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    await _service.cacheOrders(orders);
  }

  Future<List<Map<String, dynamic>>?> getCachedOrders() async {
    return await _service.getCachedOrders();
  }

  Future<void> enqueueAction(SyncActionType type, Map<String, dynamic> data) async {
    await _service.enqueueAction(type, data);
    _pendingActionsCount = _service.pendingActionsCount;
    notifyListeners();
  }

  Future<void> processSyncQueue() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    await _service.processSyncQueue();

    _isSyncing = false;
    _pendingActionsCount = _service.pendingActionsCount;
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _service.clearCache();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
