import 'package:flutter/foundation.dart';

import '../models/driver_subscription_model.dart';
import '../services/driver_subscription_service.dart';

class DriverSubscriptionProvider extends ChangeNotifier {
  final DriverSubscriptionService _service = DriverSubscriptionService();

  String? _currentDriverId;
  DriverSubscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;

  String? get currentDriverId => _currentDriverId;
  DriverSubscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSubscription => _currentSubscription != null;
  bool get isActiveSubscription => _currentSubscription?.isActive ?? false;

  DriverSubscriptionPlanInfo? get currentPlanInfo {
    if (_currentSubscription == null) return null;
    return _service.getPlanBenefits(_currentSubscription!.planType);
  }

  int get maxConcurrentDeliveries =>
      currentPlanInfo?.maxConcurrentDeliveries ?? 1;

  bool get hasPriorityDispatch =>
      currentPlanInfo?.priorityDispatch ?? false;

  bool get hasBatchedRoutes =>
      currentPlanInfo?.batchedRoutes ?? false;

  void loadSubscription(String driverId) {
    _currentDriverId = driverId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    _currentSubscription = _service.getSubscription(driverId);
    if (_currentSubscription != null) {
      _service.checkExpiration(driverId);
      _currentSubscription = _service.getSubscription(driverId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> subscribe(DriverSubscriptionPlan planType) async {
    if (_currentDriverId == null) {
      _error = 'No driver ID set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = _service.subscribe(_currentDriverId!, planType);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelSubscription() async {
    if (_currentDriverId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = _service.cancelSubscription(_currentDriverId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> renewSubscription() async {
    if (_currentDriverId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = _service.renewSubscription(_currentDriverId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void checkExpiration() {
    if (_currentDriverId == null) return;

    _service.checkExpiration(_currentDriverId!);
    _currentSubscription = _service.getSubscription(_currentDriverId);
    notifyListeners();
  }

  List<DriverSubscriptionPlanInfo> getAllPlans() {
    return _service.getAllPlans();
  }

  DriverSubscriptionPlanInfo getPlanBenefits(DriverSubscriptionPlan planType) {
    return _service.getPlanBenefits(planType);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentDriverId = null;
    _currentSubscription = null;
    super.dispose();
  }
}
