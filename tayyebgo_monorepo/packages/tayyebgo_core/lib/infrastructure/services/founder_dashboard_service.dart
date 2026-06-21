import 'package:cloud_firestore/cloud_firestore.dart';

class FounderDashboardMetrics {
  final int ordersPerDay;
  final double revenuePerDay;
  final int activeDrivers;
  final int activeStores;
  final double customerRetention;
  final double profitPerOrder;
  final int totalCustomers;
  final int totalDrivers;
  final int totalStores;
  final bool isHealthy;

  const FounderDashboardMetrics({
    required this.ordersPerDay,
    required this.revenuePerDay,
    required this.activeDrivers,
    required this.activeStores,
    required this.customerRetention,
    required this.profitPerOrder,
    required this.totalCustomers,
    required this.totalDrivers,
    required this.totalStores,
    required this.isHealthy,
  });

  Map<String, dynamic> toMap() => {
        'ordersPerDay': ordersPerDay,
        'revenuePerDay': revenuePerDay,
        'activeDrivers': activeDrivers,
        'activeStores': activeStores,
        'customerRetention': customerRetention,
        'profitPerOrder': profitPerOrder,
        'totalCustomers': totalCustomers,
        'totalDrivers': totalDrivers,
        'totalStores': totalStores,
        'isHealthy': isHealthy,
      };

  List<String> get healthIssues {
    final issues = <String>[];
    if (ordersPerDay < 10) issues.add('Low order volume');
    if (activeDrivers < 5) issues.add('Too few active drivers');
    if (activeStores < 3) issues.add('Too few active stores');
    if (customerRetention < 0.3) issues.add('Low customer retention');
    if (profitPerOrder < 0) issues.add('Negative profit per order');
    return issues;
  }
}

class FounderDashboardService {
  static final FounderDashboardService instance =
      FounderDashboardService._();
  FounderDashboardService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<FounderDashboardMetrics> getMetrics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final last7d = now.subtract(const Duration(days: 7));

    final ordersSnap = await _db
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();

    final totalOrdersToday = ordersSnap.docs.length;
    double revenueToday = 0;
    for (final doc in ordersSnap.docs) {
      revenueToday +=
          (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
    }

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

    final customersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .get();
    final totalCustomers = customersSnap.docs.length;

    final allDriversSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();
    final totalDrivers = allDriversSnap.docs.length;

    final allStoresSnap =
        await _db.collection('restaurants').get();
    final totalStores = allStoresSnap.docs.length;

    double retention = 0;
    try {
      final orders7dSnap = await _db
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(last7d))
          .get();

      final Map<String, int> customerOrderCounts = {};
      for (final doc in orders7dSnap.docs) {
        final cid = doc.data()['customerId'] as String? ?? '';
        if (cid.isNotEmpty) {
          customerOrderCounts[cid] = (customerOrderCounts[cid] ?? 0) + 1;
        }
      }
      final returning =
          customerOrderCounts.values.where((v) => v > 1).length;
      retention = customerOrderCounts.isNotEmpty
          ? returning / customerOrderCounts.length
          : 0;
    } catch (_) {} // Retention calc failure should not block dashboard load

    const avgDriverCost = 12000.0;
    const avgPlatformCost = 2000.0;
    const commissionRate = 0.10;
    final avgOrderValue =
        totalOrdersToday > 0 ? revenueToday / totalOrdersToday : 0.0;
    final profitPerOrder =
        (avgOrderValue * commissionRate) - avgDriverCost - avgPlatformCost;

    final isHealthy = totalOrdersToday >= 10 &&
        activeDrivers >= 5 &&
        activeStores >= 3 &&
        profitPerOrder >= 0;

    return FounderDashboardMetrics(
      ordersPerDay: totalOrdersToday,
      revenuePerDay: revenueToday,
      activeDrivers: activeDrivers,
      activeStores: activeStores,
      customerRetention: retention,
      profitPerOrder: profitPerOrder,
      totalCustomers: totalCustomers,
      totalDrivers: totalDrivers,
      totalStores: totalStores,
      isHealthy: isHealthy,
    );
  }
}
