import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Map<String, dynamic> _docToMap(DocumentSnapshot<Object?> d) {
  return <String, dynamic>{'id': d.id, ...d.data() as Map<String, dynamic>};
}

class PartnerHomeProvider extends ChangeNotifier {
  Stream<List<Map<String, dynamic>>> watchOrders(String? restaurantId, List<String> statuses) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('status', whereIn: statuses);
    if (restaurantId != null) {
      query = query.where('restaurantId', isEqualTo: restaurantId);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Stream<List<Map<String, dynamic>>> watchKitchenOrders(String restaurantId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', whereIn: ['accepted', 'preparing'])
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Stream<Map<String, dynamic>?> watchRestaurant(String restaurantId) {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  Stream<List<Map<String, dynamic>>> watchMenuItems(String? restaurantId) {
    Query query = FirebaseFirestore.instance
        .collection('menu_items');
    if (restaurantId != null) {
      query = query.where('restaurantId', isEqualTo: restaurantId);
    }
    return query
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Stream<List<Map<String, dynamic>>> watchDrivers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Stream<List<Map<String, dynamic>>> watchPromos(String? restaurantId) {
    Query query = FirebaseFirestore.instance
        .collection('promos');
    if (restaurantId != null) {
      query = query.where('restaurantId', isEqualTo: restaurantId);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToMap).toList());
  }

  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .update(data);
  }

  Future<Map<String, dynamic>?> getRestaurant(String restaurantId) async {
    final doc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> addMenuItem(String restaurantId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('menu_items').add({
      ...data,
      'restaurantId': restaurantId,
    });
  }
}
