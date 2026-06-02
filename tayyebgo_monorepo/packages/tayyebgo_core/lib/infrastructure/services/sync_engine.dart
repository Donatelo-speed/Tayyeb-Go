import 'dart:async';
import '../../domain/enums/pending_operation_type.dart';
import 'connectivity_service.dart';
import 'offline_queue.dart';
import '../repositories/firebase_order_repository.dart';

class SyncEngine {
  static final SyncEngine instance = SyncEngine._();
  SyncEngine._();

  StreamSubscription<bool>? _connectivitySub;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    final connectivity = ConnectivityService.instance;
    connectivity.init();
    _connectivitySub = connectivity.onConnectivityChanged.listen((online) {
      if (online) _processQueue();
    });
    _processQueue();
  }

  void stop() {
    _running = false;
    _connectivitySub?.cancel();
  }

  Future<void> _processQueue() async {
    final queue = OfflineQueue.instance;
    final remote = FirebaseOrderRepository.instance;
    final ops = await queue.peekAll();
    if (ops.isEmpty) return;

    for (final op in ops) {
      try {
        if (op.type == PendingOperationType.transitionOrder &&
            op.newStatus != null) {
          await remote.transitionOrder(
            orderId: op.orderId,
            newStatus: op.newStatus!,
            actorId: op.actorId,
            latitude: op.location?.latitude,
            longitude: op.location?.longitude,
          );
        } else if (op.type == PendingOperationType.rejectOrder) {
          await remote.rejectOrder(
            orderId: op.orderId,
            actorId: op.actorId,
            reason: op.rejectionReason,
          );
        }
        await queue.dequeue(op.id);
      } catch (e) {
        await queue.updateRetry(op.id, op.retryCount + 1);
      }
    }
  }
}