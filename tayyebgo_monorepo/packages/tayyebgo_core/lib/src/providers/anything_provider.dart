import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/anything_request_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

class AnythingProvider extends ChangeNotifier {
  List<AnythingRequestModel> _myRequests = [];
  List<AnythingRequestModel> _availableRequests = [];
  bool _isLoading = false;
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

      final doc = await FirebaseFirestore.instance.collection('anything_requests').add({
        'customerId': user.id,
        'customerName': user.displayName,
        'customerPhone': user.phone,
        'storeName': storeName,
        'items': items,
        'budget': budget,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'instructions': instructions,
        'status': AnythingRequestStatus.pending.firestoreValue,
        'dropoffLatitude': dropoffLatitude,
        'dropoffLongitude': dropoffLongitude,
        'dropoffAddress': dropoffAddress,
        'paymentMethod': paymentMethod,
        'deliveryFee': 0,
        'totalCost': 0,
        'isPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return doc.id;
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

      final snap = await FirebaseFirestore.instance
          .collection('anything_requests')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _myRequests = snap.docs
          .map((d) => AnythingRequestModel.fromFirestore(d))
          .toList();

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

      final snap = await FirebaseFirestore.instance
          .collection('anything_requests')
          .where('status', isEqualTo: AnythingRequestStatus.pending.firestoreValue)
          .orderBy('createdAt', descending: true)
          .get();

      _availableRequests = snap.docs
          .map((d) => AnythingRequestModel.fromFirestore(d))
          .where((r) => r.driverId == null)
          .toList();

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
      await FirebaseFirestore.instance
          .collection('anything_requests')
          .doc(requestId)
          .update({
        'status': AnythingRequestStatus.accepted.firestoreValue,
        'driverId': driverId,
        'driverName': driverName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadAvailableRequests(_lastDriverId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String requestId, AnythingRequestStatus status) async {
    try {
      final data = <String, dynamic>{
        'status': status.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == AnythingRequestStatus.delivered) {
        data['deliveredAt'] = FieldValue.serverTimestamp();
      }
      await FirebaseFirestore.instance
          .collection('anything_requests')
          .doc(requestId)
          .update(data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateDriverLocation(String requestId, double lat, double lng) async {
    try {
      await FirebaseFirestore.instance
          .collection('anything_requests')
          .doc(requestId)
          .update({
        'driverLatitude': lat,
        'driverLongitude': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('anything_requests')
          .doc(requestId)
          .update({
        'status': AnythingRequestStatus.cancelled.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final uid = AuthProvider.instance?.user?.id;
      if (uid != null) await loadMyRequests(uid);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Stream<DocumentSnapshot> streamRequest(String requestId) {
    return FirebaseFirestore.instance
        .collection('anything_requests')
        .doc(requestId)
        .snapshots();
  }

  void clear() {
    _myRequests = [];
    _availableRequests = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
