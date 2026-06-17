import 'package:flutter/foundation.dart';

import '../models/partner_subscription_model.dart';
import '../services/partner_subscription_service.dart';

class PartnerSubscriptionProvider extends ChangeNotifier {
  final PartnerSubscriptionService _service = PartnerSubscriptionService();

  String? _currentRestaurantId;
  PartnerSubscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;

  String? get currentRestaurantId => _currentRestaurantId;
  PartnerSubscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSubscription => _currentSubscription != null;
  bool get isActiveSubscription => _currentSubscription?.isActive ?? false;

  PartnerTierInfo? get currentTierInfo {
    if (_currentSubscription == null) return null;
    return _service.getTierBenefits(_currentSubscription!.tier);
  }

  double get commissionRate =>
      _currentSubscription?.commissionRate ?? 10.0;

  List<String> get benefits =>
      _currentSubscription?.benefits ?? [];

  Future<void> loadSubscription(String restaurantId) async {
    _currentRestaurantId = restaurantId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.checkExpiration(restaurantId);
      _currentSubscription = await _service.getSubscription(restaurantId);
    } catch (e) {
      _error = 'Failed to load subscription: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> subscribe(PartnerTier tier) async {
    if (_currentRestaurantId == null) {
      _error = 'No restaurant ID set';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = await _service.subscribe(_currentRestaurantId!, tier);
      if (_currentSubscription == null) {
        _error = 'Failed to create subscription';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelSubscription() async {
    if (_currentRestaurantId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = await _service.cancelSubscription(_currentRestaurantId!);
      if (_currentSubscription == null) {
        _error = 'Failed to cancel subscription';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradeTier(PartnerTier newTier) async {
    if (_currentRestaurantId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = await _service.upgradeTier(_currentRestaurantId!, newTier);
      if (_currentSubscription == null) {
        _error = 'Failed to upgrade tier';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  PartnerTierInfo getTierBenefits(PartnerTier tier) {
    return _service.getTierBenefits(tier);
  }

  double getCommissionRate(PartnerTier tier) {
    return _service.getCommissionRate(tier);
  }

  List<PartnerTierInfo> getAllTiers() {
    return _service.getAllTiers();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentRestaurantId = null;
    _currentSubscription = null;
    super.dispose();
  }
}
