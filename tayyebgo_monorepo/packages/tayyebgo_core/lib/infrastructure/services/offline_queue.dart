import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/value_objects/pending_operation.dart';

class OfflineQueue {
  static final OfflineQueue instance = OfflineQueue._();
  OfflineQueue._();
  static const _key = 'pending_operations';

  List<PendingOperation> _queue = [];
  bool _loaded = false;

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
}