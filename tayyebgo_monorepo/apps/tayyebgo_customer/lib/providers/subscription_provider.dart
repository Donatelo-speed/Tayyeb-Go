import 'package:flutter/foundation.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class SubscriptionProvider extends ChangeNotifier {
  CustomerSubscription? _activeSubscription;
  List<CustomerSubscription> _history = [];
  bool _isLoading = false;
  String? _error;

  CustomerSubscription? get activeSubscription => _activeSubscription;
  List<CustomerSubscription> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubscribed => _activeSubscription?.isActive == true;

  Stream<CustomerSubscription?>? watchSubscription(String userId) {
    return SubscriptionService.instance.watchActiveSubscription(userId);
  }

  Future<void> loadSubscription(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _activeSubscription = await SubscriptionService.instance.getActiveSubscription(userId);
      _history = await SubscriptionService.instance.getSubscriptionHistory(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> subscribe(String userId, SubscriptionPlanType plan, String transactionId) async {
    try {
      final sub = await SubscriptionService.instance.subscribe(
        userId: userId,
        plan: plan,
        paymentTransactionId: transactionId,
      );
      if (sub != null) {
        _activeSubscription = sub;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> cancel(String reason) async {
    if (_activeSubscription == null) return;
    await SubscriptionService.instance.cancel(_activeSubscription!.id, reason);
    _activeSubscription = null;
    notifyListeners();
  }
}
