import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/value_objects/pending_operation.dart';

class OfflineQueue {
  static final OfflineQueue instance = OfflineQueue._();
  OfflineQueue._();
  static const _key = 'pending_operations';
  static const _maxRetries = 5;
  static const _baseRetryDelay = Duration(seconds: 1);

  List<PendingOperation> _queue = [];
  bool _loaded = false;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      _queue = list
          .map((e) => PendingOperation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_queue.map((op) => op.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> enqueue(PendingOperation op) async {
    await _ensureLoaded();
    _queue.add(op);
    await _persist();
  }

  Future<List<PendingOperation>> peekAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_queue);
  }

  Future<void> dequeue(String operationId) async {
    await _ensureLoaded();
    _queue.removeWhere((op) => op.id == operationId);
    await _persist();
  }

  Future<void> updateRetry(String operationId, int retryCount) async {
    await _ensureLoaded();
    final idx = _queue.indexWhere((op) => op.id == operationId);
    if (idx >= 0) {
      _queue[idx] = _queue[idx].copyWith(retryCount: retryCount);
      await _persist();
    }
  }

  Future<void> clear() async {
    _queue = [];
    await _persist();
  }

  int get pendingCount => _queue.length;

  /// Start automatic sync when connection is restored
  void startAutoSync({
    Future<bool> Function(PendingOperation)? executeOperation,
  }) {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        sync(executeOperation: executeOperation);
      }
    });
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Sync all pending operations with exponential backoff retry
  Future<void> sync({
    Future<bool> Function(PendingOperation)? executeOperation,
  }) async {
    if (_isSyncing || _queue.isEmpty) return;
    _isSyncing = true;

    try {
      await _ensureLoaded();
      final operations = List<PendingOperation>.from(_queue);

      for (final operation in operations) {
        if (operation.retryCount >= _maxRetries) {
          await dequeue(operation.id);
          continue;
        }

        bool success = false;
        if (executeOperation != null) {
          try {
            success = await executeOperation(operation);
          } catch (e) {
            success = false;
          }
        }

        if (success) {
          await dequeue(operation.id);
        } else {
          final retryCount = operation.retryCount + 1;
          await updateRetry(operation.id, retryCount);
          
          // Exponential backoff
          final delay = _baseRetryDelay * (1 << retryCount);
          await Future.delayed(delay);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }
}