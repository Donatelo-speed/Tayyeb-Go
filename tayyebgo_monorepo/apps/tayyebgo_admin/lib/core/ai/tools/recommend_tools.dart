import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';

class RecommendOperationsTool extends AgentTool {
  @override
  String get name => 'recommend_operations';
  @override
  String get description => 'Recommend operational improvements based on live metrics (driver coverage, prep time, queue).';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {};

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('orders').where('status', whereIn: ['placed', 'accepted', 'preparing']).get(),
      db.collection('Users').where('role', isEqualTo: 'driver').limit(200).get(),
      db.collection('Restaurants').get(),
    ]);
    final activeOrders = results[0].size;
    final drivers = results[1].docs;
    final onlineDrivers = drivers.where((d) {
      final data = d.data();
      return data['isOnline'] == true || data['status'] == 'active' || data['status'] == 'on_delivery';
    }).length;
    final totalDrivers = drivers.length;
    final stores = results[2].size;
    final inactive = results[2].docs.where((d) => d.data()['isActive'] == false).length;

    final recs = <Map<String, String>>[];
    if (activeOrders > onlineDrivers && onlineDrivers > 0) {
      recs.add({
        'priority': 'high',
        'title': 'Driver shortage',
        'detail': '$activeOrders active orders vs $onlineDrivers online drivers. Approve pending drivers, send shift reminders, or switch hybrid stores to platform fallback.',
      });
    } else if (onlineDrivers == 0 && activeOrders > 0) {
      recs.add({
        'priority': 'critical',
        'title': 'No drivers online',
        'detail': 'No drivers online but $activeOrders orders are pending. Send push notifications to verified drivers.',
      });
    }
    if (inactive > 0) {
      recs.add({
        'priority': 'medium',
        'title': '$inactive inactive stores',
        'detail': 'Inactive stores reduce customer choice. Reach out to owners to re-engage or feature active alternatives.',
      });
    }
    if (activeOrders > 50) {
      recs.add({
        'priority': 'high',
        'title': 'High queue',
        'detail': 'Order queue is large ($activeOrders). Consider temporary boost campaigns or pause slow stores from new orders.',
      });
    }
    if (recs.isEmpty) {
      recs.add({
        'priority': 'low',
        'title': 'Operations look healthy',
        'detail': 'No urgent issues. Keep monitoring driver coverage and order prep time.',
      });
    }
    return ToolResult.ok(
      name,
      {
        'recommendations': recs,
        'context': {
          'activeOrders': activeOrders,
          'onlineDrivers': onlineDrivers,
          'totalDrivers': totalDrivers,
          'stores': stores,
        },
      },
      summary: 'Generated ${recs.length} operational recommendation(s).',
    );
  }
}

class RecommendDriverAllocationTool extends AgentTool {
  @override
  String get name => 'recommend_driver_allocation';
  @override
  String get description => 'Recommend driver allocation per zone/store based on current order density.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {};

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('orders').where('status', whereIn: ['placed', 'accepted', 'preparing']).get(),
      db.collection('Users').where('role', isEqualTo: 'driver').limit(500).get(),
    ]);
    final orders = results[0].docs;
    final drivers = results[1].docs;
    final ordersByZone = <String, int>{};
    for (final doc in orders) {
      final zone = doc.data()['zone'] as String? ?? 'unassigned';
      ordersByZone[zone] = (ordersByZone[zone] ?? 0) + 1;
    }
    final driversByZone = <String, int>{};
    for (final doc in drivers) {
      final data = doc.data();
      if (data['isOnline'] != true && data['status'] != 'active' && data['status'] != 'on_delivery') continue;
      final zone = data['zone'] as String? ?? 'unassigned';
      driversByZone[zone] = (driversByZone[zone] ?? 0) + 1;
    }
    final recs = <Map<String, dynamic>>[];
    for (final entry in ordersByZone.entries) {
      final zone = entry.key;
      final od = entry.value;
      final dd = driversByZone[zone] ?? 0;
      final ratio = dd == 0 ? double.infinity : od / dd;
      String priority;
      String recommendation;
      if (dd == 0 && od > 0) {
        priority = 'critical';
        recommendation = 'Zone $zone has $od orders and zero online drivers. Broadcast shift request to drivers in adjacent zones or expand platform fallback.';
      } else if (ratio > 4) {
        priority = 'high';
        recommendation = 'Zone $zone is overloaded (ratio $ratio). Move idle drivers from low-traffic zones or enable platform fallback for hybrid stores.';
      } else {
        continue;
      }
      recs.add({'zone': zone, 'priority': priority, 'orders': od, 'drivers': dd, 'recommendation': recommendation});
    }
    if (recs.isEmpty) {
      recs.add({'zone': 'all', 'priority': 'low', 'recommendation': 'Driver allocation looks balanced across zones.'});
    }
    return ToolResult.ok(name, {'recommendations': recs},
        summary: 'Driver allocation: ${recs.length} recommendation(s).');
  }
}

class RecommendMarketingTool extends AgentTool {
  @override
  String get name => 'recommend_marketing';
  @override
  String get description => 'Recommend marketing campaigns: coupons, re-engagement, churned users, peak-hour boosts.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {};

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final cutoff = Timestamp.fromDate(now.subtract(const Duration(days: 30)));
    final priorCutoff = Timestamp.fromDate(now.subtract(const Duration(days: 60)));
    final orders = await db
        .collection('orders')
        .where('createdAt', isGreaterThan: priorCutoff)
        .limit(2000)
        .get();
    final active = <String>{};
    final churned = <String>{};
    for (final doc in orders.docs) {
      final d = doc.data();
      final uid = d['userId'] as String? ?? d['customerId'] as String?;
      if (uid == null) continue;
      final ts = d['createdAt'];
      if (ts is Timestamp) {
        if (ts.compareTo(cutoff) > 0) {
          active.add(uid);
        } else {
          churned.add(uid);
        }
      }
    }
    final recs = <Map<String, String>>[];
    if (churned.isNotEmpty) {
      recs.add({
        'priority': 'high',
        'title': 'Re-engage ${churned.length} churned users',
        'detail': 'Send a "we miss you" push with 15% off coupon. Target: 30-day inactive customers.',
      });
    }
    recs.add({
      'priority': 'medium',
      'title': 'Peak-hour boost campaign',
      'detail': 'Run free-delivery promos at 12:00–14:00 and 19:00–21:00 to lift the slow midday slot.',
    });
    if (active.length > 50) {
      recs.add({
        'priority': 'low',
        'title': 'VIP tier for top 5% spenders',
        'detail': 'Identify top 5% by spend and offer free delivery + priority support.',
      });
    }
    recs.add({
      'priority': 'low',
      'title': 'Referral program',
      'detail': 'Customers who refer friends are 4x more likely to stay. Launch "Give 10, Get 10 SYP" campaign.',
    });
    return ToolResult.ok(name, {'recommendations': recs, 'activeUsers': active.length, 'churnedUsers': churned.length},
        summary: 'Marketing: ${recs.length} recommendation(s).');
  }
}

class RecommendRevenueTool extends AgentTool {
  @override
  String get name => 'recommend_revenue';
  @override
  String get description => 'Find revenue opportunities: underused stores, missing fees, refund hotspots.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {};

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('orders').where('status', whereIn: ['delivered', 'completed', 'cancelled']).limit(2000).get(),
      db.collection('Restaurants').get(),
    ]);
    final orders = results[0].docs;
    final stores = results[1].docs;

    final byStore = <String, int>{};
    int refunded = 0;
    int cancelled = 0;
    for (final doc in orders) {
      final d = doc.data();
      final sid = d['storeId'] as String? ?? 'unknown';
      byStore[sid] = (byStore[sid] ?? 0) + 1;
      if (d['refunded'] == true) refunded++;
      if (d['status'] == 'cancelled') cancelled++;
    }

    final lowVolume = <String>[];
    for (final s in stores) {
      final sid = s.id;
      final active = s.data()['isActive'] == true;
      final ordersForStore = byStore[sid] ?? 0;
      if (active && ordersForStore < 10) lowVolume.add(sid);
    }

    final recs = <Map<String, String>>[];
    if (lowVolume.isNotEmpty) {
      recs.add({
        'priority': 'high',
        'title': '${lowVolume.length} active stores are underused',
        'detail': 'Boost with featured placement, send onboarding tips, or temporarily suspend underperformers.',
      });
    }
    if (cancelled > orders.length * 0.1) {
      recs.add({
        'priority': 'medium',
        'title': 'High cancellation rate',
        'detail': '${(cancelled / orders.length * 100).toStringAsFixed(1)}% of orders are cancelled. Add cancellation-fee policy or monitor the worst stores.',
      });
    }
    if (refunded > 0) {
      recs.add({
        'priority': 'medium',
        'title': '$refunded refunded orders',
        'detail': 'Investigate refund patterns. Most refunds cluster in 1-2 stores; coaching those owners recovers revenue.',
      });
    }
    recs.add({
      'priority': 'low',
      'title': 'Promote premium tier',
      'detail': 'Convert free-tier stores to Professional/Enterprise for predictable MRR. Target stores with > 50 orders/mo first.',
    });
    return ToolResult.ok(name, {'recommendations': recs},
        summary: 'Revenue: ${recs.length} opportunity/ies.');
  }
}
