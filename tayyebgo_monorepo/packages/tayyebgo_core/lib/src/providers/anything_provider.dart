import 'package:flutter/foundation.dart';
import '../models/anything_request_model.dart';
import '../models/user_model.dart';
import '../di/app_locator.dart';

class AnythingProvider extends ChangeNotifier {
  List<AnythingRequestModel> _myRequests = [];
  List<AnythingRequestModel> _availableRequests = [];
  bool _isLoading = false;
  bool _disposed = false;
  String? _error;
  String? _lastDriverId;

  List<AnythingRequestModel> get myRequests => _myRequests;
  List<AnythingRequestModel> get availableRequests => _availableRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String?> createRequest({
    required UserModel user,
    required String storeName,
    required List<Map<String, dynamic>> items,
    required double budget,
    String? photoUrl,
    String instructions = '',
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String dropoffAddress,
    String paymentMethod = 'cash',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docId = await AppLocator.instance.anything.createRequest(
        customerId: user.id,
        customerName: user.displayName,
        customerPhone: user.phone ?? '',
        storeName: storeName,
        items: items,
        budget: budget,
        photoUrl: photoUrl,
        instructions: instructions,
        dropoffLatitude: dropoffLatitude,
        dropoffLongitude: dropoffLongitude,
        dropoffAddress: dropoffAddress,
        paymentMethod: paymentMethod,
      );

      _isLoading = false;
      notifyListeners();
      return docId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMyRequests(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await AppLocator.instance.anything.getRequestsForCustomer(userId);
      _myRequests = data.map((d) => AnythingRequestModel.fromMap(d['id'] as String, d)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailableRequests(String? excludeDriverId) async {
    try {
      _isLoading = true;
      _lastDriverId = excludeDriverId;
      notifyListeners();

      final data = await AppLocator.instance.anything.getAvailableRequests();
      _availableRequests = data.map((d) => AnythingRequestModel.fromMap(d['id'] as String, d)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptRequest(String requestId, String driverId, String driverName) async {
    try {
      final success = await AppLocator.instance.anything.acceptRequest(requestId, driverId, driverName);
      if (success) await loadAvailableRequests(_lastDriverId);
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String requestId, AnythingRequestStatus status) async {
    try {
      return await AppLocator.instance.anything.updateStatus(requestId, status.firestoreValue);
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateDriverLocation(String requestId, double lat, double lng) async {
    try {
      return await AppLocator.instance.anything.updateDriverLocation(requestId, lat, lng);
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    try {
      final success = await AppLocator.instance.anything.cancelRequest(requestId);
      if (success) {
        final uid = _lastDriverId;
        if (uid != null) await loadMyRequests(uid);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Stream<Map<String, dynamic>> streamRequest(String requestId) {
    return AppLocator.instance.anything.watchRequest(requestId);
  }

  void clear() {
    _myRequests = [];
    _availableRequests = [];
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
