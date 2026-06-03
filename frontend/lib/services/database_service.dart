import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static FirebaseFirestore get instance => _db;

  static CollectionReference get users => _db.collection('users');
  static CollectionReference get restaurants => _db.collection('restaurants');
  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get menuItems => _db.collection('menu_items');
  static CollectionReference get drivers => _db.collection('drivers');

  static Stream<QuerySnapshot> streamCollection(String collection) {
    return _db.collection(collection).snapshots();
  }

  static Future<DocumentSnapshot> getDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).get();
  }

  static Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(collection).doc(docId).update(data);
    } catch (e) {
      debugPrint('updateDocument error: $e');
      rethrow;
    }
  }

  static Future<void> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(collection).add(data);
    } catch (e) {
      debugPrint('createDocument error: $e');
      rethrow;
    }
  }

  static Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _db.collection(collection).doc(docId).delete();
    } catch (e) {
      debugPrint('deleteDocument error: $e');
      rethrow;
    }
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Stream<List<Map<String, dynamic>>> streamRestaurants() {
    return FirestoreService.restaurants.snapshots().map(
      (snap) => snap.docs.map(_docToMap).toList(),
    );
  }

  Stream<List<Map<String, dynamic>>> streamOrders({
    String? vendorId,
    String? status,
  }) {
    Query query = FirestoreService.orders;
    if (vendorId != null) {
      query = query.where('vendorId', isEqualTo: vendorId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Stream<List<Map<String, dynamic>>> streamMenuItems(String vendorId) {
    return FirestoreService.menuItems
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Stream<List<Map<String, dynamic>>> streamUsers() {
    return FirestoreService.users.snapshots().map(
      (snap) => snap.docs.map(_docToMap).toList(),
    );
  }

  Stream<List<Map<String, dynamic>>> streamDriverOrders() {
    return FirestoreService.orders
        .where('status', isEqualTo: 'ready_for_driver')
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Stream<List<Map<String, dynamic>>> streamActiveDeliveries(String driverId) {
    return FirestoreService.orders
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['accepted', 'picked_up'])
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? driverId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (driverId != null) data['driverId'] = driverId;
      await FirestoreService.orders.doc(orderId).update(data);
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
      rethrow;
    }
  }

  Future<void> acceptOrder(String orderId, String driverId) async {
    try {
      await FirestoreService.orders.doc(orderId).update({
        'status': 'accepted',
        'driverId': driverId,
        'acceptedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('acceptOrder error: $e');
      rethrow;
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await FirestoreService.users.doc(userId).update({'role': role});
    } catch (e) {
      debugPrint('updateUserRole error: $e');
      rethrow;
    }
  }

  Future<void> toggleRestaurantStatus(
    String restaurantId,
    bool isActive,
  ) async {
    try {
      await FirestoreService.restaurants.doc(restaurantId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('toggleRestaurantStatus error: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(String itemId, Map<String, dynamic> data) async {
    try {
      await FirestoreService.menuItems.doc(itemId).update(data);
    } catch (e) {
      debugPrint('updateMenuItem error: $e');
      rethrow;
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    try {
      await FirestoreService.menuItems.add(data);
    } catch (e) {
      debugPrint('addMenuItem error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _docToMap(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return <String, dynamic>{'id': doc.id, ...data};
  }

  Future<void> addRestaurant(Map<String, dynamic> data) async {
    try {
      await FirestoreService.restaurants.add(data);
    } catch (e) {
      debugPrint('addRestaurant error: $e');
      rethrow;
    }
  }
}

class AppNavigator extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}

class OrderStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String preparing = 'preparing';
  static const String readyForDriver = 'ready_for_driver';
  static const String pickedUp = 'picked_up';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case accepted:
        return 'Accepted';
      case preparing:
        return 'Preparing';
      case readyForDriver:
        return 'Ready for Driver';
      case pickedUp:
        return 'Picked Up';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      case accepted:
        return Colors.blue;
      case preparing:
        return Colors.purple;
      case readyForDriver:
        return Colors.cyan;
      case pickedUp:
        return Colors.amber;
      case delivered:
        return Colors.green;
      case cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
