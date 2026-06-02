import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class OfflineQueueProvider extends ChangeNotifier {
  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  Future<void> load() async {
    final ops = await OfflineQueue.instance.peekAll();
    _pendingCount = ops.length;
    notifyListeners();
  }

  Future<void> enqueue(PendingOperation op) async {
    await OfflineQueue.instance.enqueue(op);
    _pendingCount++;
    notifyListeners();
  }

  Future<void> dequeue(String id) async {
    await OfflineQueue.instance.dequeue(id);
    _pendingCount = (await OfflineQueue.instance.peekAll()).length;
    notifyListeners();
  }

  Future<void> refresh() async {
    await load();
  }
}
