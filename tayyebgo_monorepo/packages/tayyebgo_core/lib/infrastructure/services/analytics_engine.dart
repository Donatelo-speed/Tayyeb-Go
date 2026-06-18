import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BusinessMetrics {
  final int totalOrders;
  final int activeUsers;
  final int activeDrivers;
  final int activeStores;
  final double totalRevenue;
  final double averageOrderValue;
  final double avgDeliveryTimeMinutes;
  final double cancellationRate;
  final double profitPerOrder;
  final double customerRetentionRate;
  final List<DailyMetric> dailyTrend;

  const BusinessMetrics({
    required this.totalOrders,
    required this.activeUsers,
    required this.activeDrivers,
    required this.activeStores,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.avgDeliveryTimeMinutes,
    required this.cancellationRate,
    required this.profitPerOrder,
    required this.customerRetentionRate,
    this.dailyTrend = const [],
  });

  Map<String, dynamic> toMap() => {
        'totalOrders': totalOrders,
        'activeUsers': activeUsers,
        'activeDrivers': activeDrivers,
        'activeStores': activeStores,
        'totalRevenue': totalRevenue,
        'averageOrderValue': averageOrderValue,
        'avgDeliveryTimeMinutes': avgDeliveryTimeMinutes,
        'cancellationRate': cancellationRate,
        'profitPerOrder': profitPerOrder,
        'customerRetentionRate': customerRetentionRate,
      };
}

class DailyMetric {
  final DateTime date;
  final int orders;
  final double revenue;
  final int activeUsers;

  const DailyMetric({
    required this.date,
    required this.orders,
    required this.revenue,
    required this.activeUsers,
  });
}

class DriverAnalytics {
  final String driverId;
  final String driverName;
  final int totalDeliveries;
  final int completedDeliveries;
  final double acceptanceRate;
  final double completionRate;
  final double avgDeliveryTimeMinutes;
  final double totalDistanceKm;
  final double earningsPerHour;
  final double rating;
  final int activeHoursToday;

  const DriverAnalytics({
    required this.driverId,
    required this.driverName,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.acceptanceRate,
    required this.completionRate,
    required this.avgDeliveryTimeMinutes,
    required this.totalDistanceKm,
    required this.earningsPerHour,
    required this.rating,
    required this.activeHoursToday,
  });

  bool get isHighPerformer => acceptanceRate > 0.85 && completionRate > 0.95;
}

class StoreAnalytics {
  final String storeId;
  final String storeName;
  final int totalOrders;
  final double totalRevenue;
  final double avgOrderValue;
  final List<MenuItemStat> topSellers;
  final List<MenuItemStat> slowItems;
  final Map<int, int> peakHours;
  final double customerRepeatRate;
  final double avgPreparationTimeMinutes;

  const StoreAnalytics({
    required this.storeId,
    required this.storeName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.avgOrderValue,
    this.topSellers = const [],
    this.slowItems = const [],
    this.peakHours = const {},
    required this.customerRepeatRate,
    required this.avgPreparationTimeMinutes,
  });
}

class MenuItemStat {
  final String name;
  final int orderCount;
  final double revenue;

  const MenuItemStat({
    required this.name,
    required this.orderCount,
    required this.revenue,
  });
}

class AnalyticsEngine {
  static final AnalyticsEngine instance = AnalyticsEngine._();
  AnalyticsEngine._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<BusinessMetrics> getBusinessMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 7));

    try {
      final ordersSnap = await _db
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final docs = ordersSnap.docs;
      final totalOrders = docs.length;

      double totalRevenue = 0;
      double totalDeliveryTime = 0;
      int deliveredCount = 0;
      int cancelledCount = 0;
      for (final doc in docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;

        final status = data['status'] as String? ?? '';
        if (status == 'cancelled') cancelledCount++;

        if (status == 'delivered') {
          deliveredCount++;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
          if (createdAt != null && deliveredAt != null) {
            totalDeliveryTime +=
                deliveredAt.difference(createdAt).inSeconds / 60.0;
          }
        }
      }

      final avgOrderValue =
          totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
      final avgDeliveryTime =
          deliveredCount > 0 ? totalDeliveryTime / deliveredCount : 0.0;
      final cancellationRate =
          totalOrders > 0 ? cancelledCount / totalOrders : 0.0;

      final commissionRate = 0.15;
      final avgDriverCost = 12000.0;
      final avgPlatformCost = 2000.0;
      final profitPerOrder =
          (avgOrderValue * commissionRate) - avgDriverCost - avgPlatformCost;

      final uniqueCustomers = <String>{};
      final returningCustomers = <String>{};
      final customerOrderCounts = <String, int>{};
      for (final doc in docs) {
        final cid = doc.data()['customerId'] as String? ?? '';
        if (cid.isNotEmpty) {
          uniqueCustomers.add(cid);
          customerOrderCounts[cid] = (customerOrderCounts[cid] ?? 0) + 1;
        }
      }
      for (final entry in customerOrderCounts.entries) {
        if (entry.value > 1) returningCustomers.add(entry.key);
      }
      final retentionRate = uniqueCustomers.isNotEmpty
          ? returningCustomers.length / uniqueCustomers.length
          : 0.0;

      final driversSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isOnline', isEqualTo: true)
          .get();
      final activeDrivers = driversSnap.docs.length;

      final storesSnap = await _db
          .collection('restaurants')
          .where('isActive', isEqualTo: true)
          .get();
      final activeStores = storesSnap.docs.length;

      return BusinessMetrics(
        totalOrders: totalOrders,
        activeUsers: uniqueCustomers.length,
        activeDrivers: activeDrivers,
        activeStores: activeStores,
        totalRevenue: totalRevenue,
        averageOrderValue: avgOrderValue,
        avgDeliveryTimeMinutes: avgDeliveryTime,
        cancellationRate: cancellationRate,
        profitPerOrder: profitPerOrder,
        customerRetentionRate: retentionRate,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AnalyticsEngine] Error getting business metrics: $e');
      return const BusinessMetrics(
        totalOrders: 0,
        activeUsers: 0,
        activeDrivers: 0,
        activeStores: 0,
        totalRevenue: 0,
        averageOrderValue: 0,
        avgDeliveryTimeMinutes: 0,
        cancellationRate: 0,
        profitPerOrder: 0,
        customerRetentionRate: 0,
      );
    }
  }

  Future<DriverAnalytics> getDriverAnalytics(String driverId) async {
    try {
      final userDoc = await _db.collection('users').doc(driverId).get();
      final userData = userDoc.data() ?? {};
      final driverName = userData['displayName'] as String? ?? '';

      final ordersSnap = await _db
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .get();

      int completed = 0;
      int totalDeliveries = 0;
      double totalTimeMinutes = 0;
      int assignedCount = 0;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        totalDeliveries++;
        final status = data['status'] as String? ?? '';
        if (status == 'delivered') {
          completed++;
          final assigned = (data['dispatchedAt'] as Timestamp?)?.toDate();
          final delivered = (data['deliveredAt'] as Timestamp?)?.toDate();
          if (assigned != null && delivered != null) {
            totalTimeMinutes += delivered.difference(assigned).inSeconds / 60.0;
          }
        }
        if (status != 'cancelled') assignedCount++;
      }

      final acceptanceRate =
          totalDeliveries > 0 ? completed / totalDeliveries : 0.0;
      final completionRate =
          assignedCount > 0 ? completed / assignedCount : 1.0;
      final avgTime =
          completed > 0 ? totalTimeMinutes / completed : 0.0;

      return DriverAnalytics(
        driverId: driverId,
        driverName: driverName,
        totalDeliveries: totalDeliveries,
        completedDeliveries: completed,
        acceptanceRate: acceptanceRate,
        completionRate: completionRate,
        avgDeliveryTimeMinutes: avgTime,
        totalDistanceKm: 0,
        earningsPerHour: 0,
        rating: (userData['rating'] as num?)?.toDouble() ?? 5.0,
        activeHoursToday: 0,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AnalyticsEngine] Error getting driver analytics: $e');
      return DriverAnalytics(
        driverId: driverId,
        driverName: '',
        totalDeliveries: 0,
        completedDeliveries: 0,
        acceptanceRate: 0,
        completionRate: 0,
        avgDeliveryTimeMinutes: 0,
        totalDistanceKm: 0,
        earningsPerHour: 0,
        rating: 0,
        activeHoursToday: 0,
      );
    }
  }

  Future<StoreAnalytics> getStoreAnalytics(String storeId) async {
    try {
      final storeDoc =
          await _db.collection('restaurants').doc(storeId).get();
      final storeData = storeDoc.data() ?? {};
      final storeName = storeData['name'] as String? ?? '';

      final ordersSnap = await _db
          .collection('orders')
          .where('restaurantId', isEqualTo: storeId)
          .get();

      double totalRevenue = 0;
      int totalOrders = 0;
      final Map<String, int> itemCounts = {};
      final Map<String, double> itemRevenue = {};
      final Map<int, int> hourlyOrders = {};
      final Map<String, int> customerVisits = {};
      double totalPrepTime = 0;
      int prepCount = 0;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        totalOrders++;
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;

        final cid = data['customerId'] as String? ?? '';
        if (cid.isNotEmpty) {
          customerVisits[cid] = (customerVisits[cid] ?? 0) + 1;
        }

        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          hourlyOrders[createdAt.hour] = (hourlyOrders[createdAt.hour] ?? 0) + 1;
        }

        final accepted = (data['acceptedAt'] as Timestamp?)?.toDate();
        final ready = (data['readyAt'] as Timestamp?)?.toDate();
        if (accepted != null && ready != null) {
          totalPrepTime += ready.difference(accepted).inSeconds / 60.0;
          prepCount++;
        }
      }

      int returningCount = 0;
      for (final visits in customerVisits.values) {
        if (visits > 1) returningCount++;
      }
      final repeatRate = customerVisits.isNotEmpty
          ? returningCount / customerVisits.length
          : 0.0;

      final topSellers = itemCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return StoreAnalytics(
        storeId: storeId,
        storeName: storeName,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        avgOrderValue:
            totalOrders > 0 ? totalRevenue / totalOrders : 0,
        topSellers: topSellers.take(10).map((e) => MenuItemStat(
              name: e.key,
              orderCount: e.value,
              revenue: itemRevenue[e.key] ?? 0,
            )).toList(),
        peakHours: hourlyOrders,
        customerRepeatRate: repeatRate,
        avgPreparationTimeMinutes:
            prepCount > 0 ? totalPrepTime / prepCount : 0,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AnalyticsEngine] Error getting store analytics: $e');
      return StoreAnalytics(
        storeId: storeId,
        storeName: '',
        totalOrders: 0,
        totalRevenue: 0,
        avgOrderValue: 0,
        customerRepeatRate: 0,
        avgPreparationTimeMinutes: 0,
      );
    }
  }

  Future<void> trackEvent({
    required String eventName,
    required String userId,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _db.collection('analytics').add({
        'event': eventName,
        'userId': userId,
        'properties': properties ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[AnalyticsEngine] Error tracking event: $e');
    }
  }
}
