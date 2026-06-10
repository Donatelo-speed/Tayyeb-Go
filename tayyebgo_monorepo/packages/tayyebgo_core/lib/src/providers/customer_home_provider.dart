import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CustomerHomeProvider extends ChangeNotifier {
  Stream<List<Map<String, dynamic>>> watchLoyalty(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      final coins = (data?['loyaltyCoins'] as num?)?.toInt() ?? 0;
      return [{'loyaltyCoins': coins}];
    });
  }

  Stream<List<Map<String, dynamic>>> watchActiveOrders(String userId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((d) => !['delivered', 'cancelled'].contains(d['status']))
            .toList());
  }

  Stream<List<Map<String, dynamic>>> watchRestaurants(String verticalType) {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .where('isActive', isEqualTo: true)
        .where('verticalType', isEqualTo: verticalType)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Stream<List<Map<String, dynamic>>> watchFavorites(String customerId) {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .where('isActive', isEqualTo: true)
        .where('favoritedBy', arrayContains: customerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> toggleFavorite(String restaurantId, String customerId, bool currentlyFav) async {
    final doc = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
    if (currentlyFav) {
      await doc.update({'favoritedBy': FieldValue.arrayRemove([customerId])});
    } else {
      await doc.update({'favoritedBy': FieldValue.arrayUnion([customerId])});
    }
  }

  Stream<List<Map<String, dynamic>>> watchOrderHistory(String userId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((d) => ['delivered', 'cancelled'].contains(d['status']))
            .toList());
  }

  Stream<List<Map<String, dynamic>>> watchMenuItems(String restaurantId) {
    return FirebaseFirestore.instance
        .collection('menu_items')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Stream<Map<String, dynamic>?> watchOrderRaw(String orderId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }
}
