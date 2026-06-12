import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/value_objects/geo_location.dart';

class RecommendationEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get personalized restaurant recommendations for a user.
  /// Combines order history frequency, ratings, proximity, and trending.
  Future<List<Map<String, dynamic>>> getRecommendedRestaurants({
    required String userId,
    GeoLocation? userLocation,
    int limit = 10,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) return [];

      final favoriteIds = List<String>.from(userData['favoriteRestaurants'] ?? []);
      final orderHistory = await _getUserOrderHistory(userId);
      final frequentRestaurantIds = _extractFrequentRestaurants(orderHistory);
      final preferredCategories = _extractPreferredCategories(orderHistory);

      final restaurantSnap = await _firestore.collection('restaurants')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      final scored = <Map<String, dynamic>>[];
      for (final doc in restaurantSnap.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        double score = 0;

        if (favoriteIds.contains(doc.id)) score += 30;

        final freqIndex = frequentRestaurantIds.indexOf(doc.id);
        if (freqIndex >= 0) {
          score += (20 - freqIndex * 2).clamp(0, 20);
        }

        final restaurantCategories = List<String>.from(data['categories'] ?? []);
        for (final cat in restaurantCategories) {
          if (preferredCategories.contains(cat.toLowerCase())) {
            score += 10;
          }
        }

        final rating = (data['rating'] as num?)?.toDouble() ?? 0;
        score += (rating * 5).clamp(0, 25);

        final orderCount = (data['orderCount'] as num?)?.toInt() ?? 0;
        if (orderCount > 100) score += 10;
        else if (orderCount > 50) score += 5;

        if (userLocation != null) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            final dist = userLocation.distanceTo(GeoLocation(lat, lng));
            if (dist < 2000) score += 15;
            else if (dist < 5000) score += 10;
            else if (dist < 10000) score += 5;
          }
        }

        final commission = (data['commissionPercent'] as num?)?.toDouble() ?? 15;
        if (commission < 15) score += 3;

        data['recommendationScore'] = score;
        scored.add(data);
      }

      scored.sort((a, b) => (b['recommendationScore'] as double).compareTo(a['recommendationScore'] as double));
      return scored.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get "trending now" restaurants based on recent order volume.
  Future<List<Map<String, dynamic>>> getTrendingRestaurants({int limit = 5}) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final ordersSnap = await _firestore.collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      final restaurantOrderCounts = <String, int>{};
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final rid = data['restaurantId'] as String? ?? '';
        if (rid.isNotEmpty) {
          restaurantOrderCounts[rid] = (restaurantOrderCounts[rid] ?? 0) + 1;
        }
      }

      if (restaurantOrderCounts.isEmpty) return [];

      final sorted = restaurantOrderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topIds = sorted.take(limit).map((e) => e.key).toList();

      final restaurants = <Map<String, dynamic>>[];
      for (final id in topIds) {
        final doc = await _firestore.collection('restaurants').doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          data['recentOrders'] = restaurantOrderCounts[id];
          restaurants.add(data);
        }
      }
      return restaurants;
    } catch (e) {
      return [];
    }
  }

  /// Get recommended menu items based on what the user has ordered before.
  Future<List<Map<String, dynamic>>> getRecommendedMenuItems({
    required String userId,
    required String restaurantId,
    int limit = 5,
  }) async {
    try {
      final orderHistory = await _getUserOrderHistory(userId);
      final itemFrequency = <String, int>{};
      final itemNames = <String, String>{};

      for (final order in orderHistory) {
        final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
        for (final item in items) {
          final itemId = item['menuItemId'] as String? ?? item['id'] as String? ?? '';
          final itemName = item['name'] as String? ?? '';
          if (itemId.isNotEmpty) {
            itemFrequency[itemId] = (itemFrequency[itemId] ?? 0) + 1;
            itemNames[itemId] = itemName;
          }
        }
      }

      final menuSnap = await _firestore.collection('restaurants')
          .doc(restaurantId).collection('menu')
          .where('isAvailable', isEqualTo: true)
          .get();

      final scored = <Map<String, dynamic>>[];
      for (final doc in menuSnap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        double score = (itemFrequency[doc.id] ?? 0) * 10.0;
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        if (price > 0 && price < 15) score += 5;
        data['recommendationScore'] = score;
        scored.add(data);
      }

      scored.sort((a, b) => (b['recommendationScore'] as double).compareTo(a['recommendationScore'] as double));
      return scored.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get "customers also ordered" recommendations.
  Future<List<Map<String, dynamic>>> getAlsoOrderedItems({
    required String orderId,
    required String restaurantId,
    int limit = 5,
  }) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return [];
      final orderData = orderDoc.data()!;
      final currentItems = List<String>.from(
        (orderData['items'] as List? ?? []).map((i) {
          final m = i as Map;
          return m['menuItemId'] ?? m['id'] ?? '';
        }),
      );

      final similarOrders = await _firestore.collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .limit(200)
          .get();

      final itemCoOccurrence = <String, int>{};
      for (final doc in similarOrders.docs) {
        final data = doc.data();
        final items = List<String>.from(
          (data['items'] as List? ?? []).map((i) {
            final m = i as Map;
            return m['menuItemId'] ?? m['id'] ?? '';
          }),
        );
        for (final item in items) {
          if (!currentItems.contains(item) && item.isNotEmpty) {
            itemCoOccurrence[item] = (itemCoOccurrence[item] ?? 0) + 1;
          }
        }
      }

      if (itemCoOccurrence.isEmpty) return [];
      final sorted = itemCoOccurrence.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topIds = sorted.take(limit).map((e) => e.key).toList();

      final menuSnap = await _firestore.collection('restaurants')
          .doc(restaurantId).collection('menu').get();

      final results = <Map<String, dynamic>>[];
      for (final doc in menuSnap.docs) {
        if (topIds.contains(doc.id)) {
          final data = doc.data();
          data['id'] = doc.id;
          data['coOrderCount'] = itemCoOccurrence[doc.id];
          results.add(data);
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUserOrderHistory(String userId) async {
    final snap = await _firestore.collection('orders')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  List<String> _extractFrequentRestaurants(List<Map<String, dynamic>> orders) {
    final counts = <String, int>{};
    for (final order in orders) {
      final rid = order['restaurantId'] as String? ?? '';
      if (rid.isNotEmpty) counts[rid] = (counts[rid] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  Set<String> _extractPreferredCategories(List<Map<String, dynamic>> orders) {
    final counts = <String, int>{};
    for (final order in orders) {
      final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
      for (final item in items) {
        final cat = (item['category'] as String? ?? '').toLowerCase();
        if (cat.isNotEmpty) counts[cat] = (counts[cat] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toSet();
  }
}
