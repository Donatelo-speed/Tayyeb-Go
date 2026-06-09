import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_anything_repository.dart';

class FirebaseAnythingRepository implements IAnythingRepository {
  static final FirebaseAnythingRepository instance = FirebaseAnythingRepository._();
  FirebaseAnythingRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String?> createRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String storeName,
    required List<Map<String, dynamic>> items,
    required double budget,
    String? photoUrl,
    required String instructions,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String dropoffAddress,
    required String paymentMethod,
  }) async {
    final doc = await _firestore.collection('anything_requests').add({
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'storeName': storeName,
      'items': items,
      'budget': budget,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'instructions': instructions,
      'status': 'pending',
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
    return doc.id;
  }

  @override
  Future<List<Map<String, dynamic>>> getRequestsForCustomer(String userId) async {
    final snap = await _firestore
        .collection('anything_requests')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableRequests() async {
    final snap = await _firestore
        .collection('anything_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        })
        .where((r) => r['driverId'] == null)
        .toList();
  }

  @override
  Future<bool> acceptRequest(String requestId, String driverId, String driverName) async {
    await _firestore.collection('anything_requests').doc(requestId).update({
      'status': 'accepted',
      'driverId': driverId,
      'driverName': driverName,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  @override
  Future<bool> updateStatus(String requestId, String status) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'delivered') {
      data['deliveredAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('anything_requests').doc(requestId).update(data);
    return true;
  }

  @override
  Future<bool> updateDriverLocation(String requestId, double lat, double lng) async {
    await _firestore.collection('anything_requests').doc(requestId).update({
      'driverLatitude': lat,
      'driverLongitude': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    await _firestore.collection('anything_requests').doc(requestId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  @override
  Stream<Map<String, dynamic>> watchRequest(String requestId) {
    return _firestore
        .collection('anything_requests')
        .doc(requestId)
        .snapshots()
        .map((snap) {
      final data = snap.data() ?? {};
      data['id'] = snap.id;
      return data;
    });
  }
}
