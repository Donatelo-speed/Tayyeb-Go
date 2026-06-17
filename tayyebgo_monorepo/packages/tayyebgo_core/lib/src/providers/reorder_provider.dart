import 'package:flutter/foundation.dart';
import '../services/reorder_service.dart';

enum ReorderState {
  initial,
  loading,
  success,
  error,
}

class ReorderProvider extends ChangeNotifier {
  final ReorderService _reorderService = ReorderService();

  ReorderState _state = ReorderState.initial;
  ReorderResult? _reorderResult;
  ReorderData? _reorderData;
  String? _errorMessage;
  String? _currentOrderId;

  ReorderState get state => _state;
  ReorderResult? get reorderResult => _reorderResult;
  ReorderData? get reorderData => _reorderData;
  String? get errorMessage => _errorMessage;
  String? get currentOrderId => _currentOrderId;

  bool get canReorder => _reorderResult?.canReorder ?? false;
  bool get hasPriceChanges => _reorderResult?.hasPriceChanges ?? false;
  bool get hasPriceIncrease => _reorderResult?.hasPriceIncrease ?? false;
  List<String> get reasons => _reorderResult?.reasons ?? [];
  double? get updatedTotal => _reorderResult?.updatedTotal;
  List<PriceChange> get priceChanges => _reorderResult?.priceChanges ?? [];
  ReorderData? get data => _reorderData;

  Future<void> checkReorderAvailability(String orderId) async {
    _state = ReorderState.loading;
    _currentOrderId = orderId;
    _errorMessage = null;
    notifyListeners();

    try {
      _reorderResult = await _reorderService.canReorder(orderId);
      
      if (_reorderResult!.canReorder) {
        _reorderData = await _reorderService.getReorderData(orderId);
        _state = ReorderState.success;
      } else {
        _state = ReorderState.error;
        _errorMessage = _reorderResult!.reasons.join('\n');
      }
    } catch (e) {
      _state = ReorderState.error;
      _errorMessage = 'Failed to check reorder availability: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> loadReorderData(String orderId) async {
    _state = ReorderState.loading;
    _currentOrderId = orderId;
    _errorMessage = null;
    notifyListeners();

    try {
      _reorderData = await _reorderService.getReorderData(orderId);
      
      if (_reorderData != null) {
        _state = ReorderState.success;
      } else {
        _state = ReorderState.error;
        _errorMessage = 'Failed to load order data';
      }
    } catch (e) {
      _state = ReorderState.error;
      _errorMessage = 'Failed to load order data: ${e.toString()}';
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _state = ReorderState.initial;
    _reorderResult = null;
    _reorderData = null;
    _errorMessage = null;
    _currentOrderId = null;
    notifyListeners();
  }

  List<String> getUnavailabilityReasons() {
    return _reorderResult?.reasons ?? [];
  }

  double? getPriceDifference() {
    if (_reorderData == null) return null;
    
    final original = _reorderData!.originalTotal;
    final updated = _reorderData!.updatedTotal;
    
    if (updated == null) return null;
    
    return updated - original;
  }

  bool isItemAvailable(String itemId) {
    if (_reorderData == null) return false;
    
    final reorderResult = _reorderResult;
    if (reorderResult == null || !reorderResult.canReorder) return false;
    
    return true;
  }
}
