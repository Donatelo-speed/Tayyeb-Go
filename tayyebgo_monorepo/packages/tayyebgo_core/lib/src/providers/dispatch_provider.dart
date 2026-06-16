import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../infrastructure/services/auto_dispatcher.dart';
import '../di/app_locator.dart';

class DispatchProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assignedDispatches = [];
  List<Map<String, dynamic>> _activeDeliveries = [];
  bool _isLoading = false;
  bool _disposed = false;
  String? _error;
  String? _driverId;
  StreamSubscription<List<Map<String, dynamic>>>? _dispatchSub;

  List<Map<String, dynamic>> get assignedDispatches => _assignedDispatches;
  List<Map<String, dynamic>> get activeDeliveries => _activeDeliveries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void startListening(String driverId) {
    if (_driverId == driverId && _dispatchSub != null) return;
    _driverId = driverId;
    _dispatchSub?.cancel();
    _subscribe(driverId);
  }

  void _subscribe(String driverId, {int retryCount = 0}) {
    _dispatchSub = AppLocator.instance.dispatch
        .watchDispatchesForDriver(driverId)
        .listen((dispatches) {
      _isLoading = false;
      _assignedDispatches = dispatches
          .where((d) => d['status'] == 'assigned' || d['status'] == 'awaiting_acceptance')
          .toList();
      _activeDeliveries = dispatches
          .where((d) => ['accepted', 'enRoute', 'pickedUp'].contains(d['status']))
          .toList();
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (_driverId == driverId && retryCount < 5) {
        Future.delayed(Duration(seconds: (retryCount + 1) * 2), () {
          if (_driverId == driverId) {
            _subscribe(driverId, retryCount: retryCount + 1);
          }
        });
      }
    });
  }

  Future<bool> acceptDispatch(String dispatchId) async {
    try {
      final success = await AppLocator.instance.dispatch.acceptDispatch(
        dispatchId,
        _driverId ?? '',
      );
      if (!success) {
        _error = 'Failed to accept dispatch';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectDispatch(String dispatchId) async {
    try {
      final success = await AppLocator.instance.dispatch.rejectDispatch(
        dispatchId,
        _driverId ?? '',
      );
      if (success) {
        unawaited(_triggerReassignment(dispatchId));
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _triggerReassignment(String dispatchId) async {
    try {
      await AutoDispatcher.instance.reassignDriver(
        dispatchRequestId: dispatchId,
        branchId: '',
        excludeDriverId: _driverId,
      );
    } catch (_) {}
  }

  Future<bool> markPickedUp(String dispatchId, String orderId) async {
    try {
      return await AppLocator.instance.dispatch.markPickedUp(
        dispatchId,
        orderId,
        _driverId ?? '',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeDelivery(String dispatchId, String orderId) async {
    try {
      return await AppLocator.instance.dispatch.completeDelivery(
        dispatchId,
        orderId,
        _driverId ?? '',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String? getOrderIdForDispatch(String dispatchId) {
    final found = [
      ..._assignedDispatches,
      ..._activeDeliveries,
    ].firstWhere(
      (d) => d['id'] == dispatchId,
      orElse: () => <String, dynamic>{},
    );
    return found['orderId'] as String?;
  }

  void stopListening() {
    _dispatchSub?.cancel();
    _dispatchSub = null;
  }

  void clear() {
    stopListening();
    _assignedDispatches = [];
    _activeDeliveries = [];
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    super.dispose();
  }
}
