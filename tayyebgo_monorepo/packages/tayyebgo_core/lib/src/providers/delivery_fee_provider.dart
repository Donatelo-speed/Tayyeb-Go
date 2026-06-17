import 'package:flutter/foundation.dart';

import '../services/delivery_fee_service.dart';

class DeliveryFeeProvider extends ChangeNotifier {
  final DeliveryFeeService _service = DeliveryFeeService();

  DeliveryZone _selectedZone = DeliveryZone.downtown;
  double _distance = 0;
  int _orderTotal = 0;
  DeliveryEstimate? _currentEstimate;

  DeliveryZone get selectedZone => _selectedZone;
  double get distance => _distance;
  int get orderTotal => _orderTotal;
  DeliveryEstimate? get currentEstimate => _currentEstimate;

  int get currentFee => _currentEstimate?.fee ?? 0;
  int get estimatedTime => _currentEstimate?.estimatedTimeMinutes ?? 0;
  bool get isFreeDelivery => _service.isFreeDelivery(_orderTotal);
  bool get freeDeliveryEligible => _currentEstimate?.freeDeliveryEligible ?? false;

  void setZone(DeliveryZone zone) {
    _selectedZone = zone;
    _recalculate();
  }

  void setDistance(double km) {
    _distance = km;
    _recalculate();
  }

  void setOrderTotal(int total) {
    _orderTotal = total;
    _recalculate();
  }

  void updateEstimate({
    required double distance,
    required DeliveryZone zone,
    int? timeOfDay,
    double? demand,
  }) {
    _distance = distance;
    _selectedZone = zone;
    _currentEstimate = _service.getDeliveryEstimate(
      distance: distance,
      zone: zone,
      timeOfDay: timeOfDay,
      demand: demand,
    );
    notifyListeners();
  }

  void _recalculate() {
    _currentEstimate = _service.getDeliveryEstimate(
      distance: _distance,
      zone: _selectedZone,
    );
    notifyListeners();
  }

  void reset() {
    _selectedZone = DeliveryZone.downtown;
    _distance = 0;
    _orderTotal = 0;
    _currentEstimate = null;
    notifyListeners();
  }
}
