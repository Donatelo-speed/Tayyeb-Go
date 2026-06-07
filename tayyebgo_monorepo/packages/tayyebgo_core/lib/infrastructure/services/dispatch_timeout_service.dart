import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auto_dispatcher.dart';

class DispatchTimeoutService {
  static final DispatchTimeoutService instance = DispatchTimeoutService._();
  DispatchTimeoutService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;
  final Map<String, Timer> _timers = {};

  void start() {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('dispatch_requests')
        .where('status', isEqualTo: 'awaiting_acceptance')
        .snapshots()
        .listen(_handleSnapshot, onError: (_) {
      _subscription?.cancel();
      _subscription = null;
      Future.delayed(const Duration(seconds: 3), () {
        if (_subscription == null) start();
      });
    });
  }

  void _handleSnapshot(QuerySnapshot snap) {
    final activeIds = <String>{};

    for (final doc in snap.docs) {
      final id = doc.id;
      activeIds.add(id);

      if (_timers.containsKey(id)) continue;

      final data = doc.data() as Map<String, dynamic>;
      final timeoutSeconds =
          (data['acceptanceTimeoutSeconds'] as num?)?.toInt() ??
              AutoDispatcher.acceptanceTimeoutSeconds;

      _timers[id] = Timer(Duration(seconds: timeoutSeconds), () {
        _handleTimeout(id);
      });
    }

    _timers.keys
        .where((id) => !activeIds.contains(id))
        .toList()
        .forEach(_cancelTimer);
  }

  Future<void> _handleTimeout(String dispatchRequestId) async {
    _timers.remove(dispatchRequestId);

    try {
      await _firestore.runTransaction((txn) async {
        final ref = _firestore
            .collection('dispatch_requests')
            .doc(dispatchRequestId);
        final snap = await txn.get(ref);
        if (!snap.exists) return;
        final data = snap.data()!;
        if (data['status'] != 'awaiting_acceptance') return;

        final driverId = data['assignedDriverId'] as String?;

        txn.update(ref, {
          'status': 'timeout',
          'timedOutAt': FieldValue.serverTimestamp(),
          'reassignmentTriggered': true,
        });

        if (driverId != null) {
          txn.update(
            _firestore.collection('users').doc(driverId),
            {
              'currentOrderId': FieldValue.delete(),
              'activeDeliveries': FieldValue.increment(-1),
            },
          );
        }
      });

      final branchId = _firestore
          .collection('dispatch_requests')
          .doc(dispatchRequestId);
      final doc = await branchId.get();
      final data = doc.data();
      final restaurantId = data?['restaurantId'] as String? ?? '';
      final driverId = data?['assignedDriverId'] as String?;

      unawaited(AutoDispatcher.instance.reassignDriver(
        dispatchRequestId: dispatchRequestId,
        branchId: restaurantId,
        excludeDriverId: driverId,
      ));
    } catch (_) {}
  }

  void _cancelTimer(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void dispose() {
    stop();
  }
}
