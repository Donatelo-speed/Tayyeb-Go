import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';

class AnalyzeRevenueTool extends AgentTool {
  @override
  String get name => 'analyze_revenue';
  @override
  String get description => 'Analyze revenue: total, by day, by store, growth %, top performers.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'window': 'today|week|month (default: week)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final window = (args['window'] as String?) ?? 'week';
    final days = switch (window) {
      'today' => 1,
      'month' => 30,
      _ => 7,
    };
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final priorCutoff = cutoff.subtract(Duration(days: days));

    final snap = await db
        .collection('orders')
        .where('status', whereIn: ['delivered', 'completed'])
        .where('deliveredAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .limit(1000)
        .get();

    final priorSnap = await db
        .collection('orders')
        .where('status', whereIn: ['delivered', 'completed'])
        .where('deliveredAt', isGreaterThan: Timestamp.fromDate(priorCutoff))
        .where('deliveredAt', isLessThan: Timestamp.fromDate(cutoff))
        .limit(1000)
        .get();

    double total = 0;
    final byStore = <String, double>{};
    final byDay = <String, double>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final amt = (d['totalAmount'] as num?)?.toDouble() ?? 0;
      total += amt;
      final sid = d['storeId'] as String? ?? 'unknown';
      byStore[sid] = (byStore[sid] ?? 0) + amt;
      final ts = d['deliveredAt'];
      if (ts is Timestamp) {
        final day = ts.toDate().toIso8601String().substring(0, 10);
        byDay[day] = (byDay[day] ?? 0) + amt;
      }
    }

    double priorTotal = 0;
    for (final doc in priorSnap.docs) {
      priorTotal += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
    }
    final growthPct = priorTotal == 0 ? null : ((total - priorTotal) / priorTotal) * 100;
    final topStores = byStore.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ToolResult.ok(
      name,
      {
        'total': total,
        'orderCount': snap.size,
        'priorPeriodTotal': priorTotal,
        'growthPct': growthPct,
        'topStores': topStores.take(5).map((e) => {'storeId': e.key, 'revenue': e.value}).toList(),
        'byDay': byDay,
      },
      summary:
          'Revenue ($window): \$${total.toStringAsFixed(0)} '
          '${growthPct == null ? '' : '(${(growthPct >= 0 ? '+' : '')}${growthPct.toStringAsFixed(1)}% vs prior)'}'
          '. Top store: ${topStores.isNotEmpty ? "\$${topStores.first.value.toStringAsFixed(0)}" : "n/a"}.',
    );
  }
}

class AnalyzeDriverPerformanceTool extends AgentTool {
  @override
  String get name => 'analyze_driver_performance';
  @override
  String get description => 'Analyze driver performance: top performers, idle rate, avg deliveries, late deliveries.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'limit': 'top N drivers to return (default 10)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final limit = (args['limit'] as int?) ?? 10;
    final db = FirebaseFirestore.instance;
    final snap = await db
        .collection('Users')
        .where('role', isEqualTo: 'driver')
        .limit(200)
        .get();
    final drivers = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    int online = 0, onDelivery = 0, idle = 0;
    for (final d in drivers) {
      final s = d['status'] as String? ?? '';
      if (s == 'on_delivery') onDelivery++;
      else if (d['isOnline'] == true || s == 'active') online++;
      else idle++;
    }
    drivers.sort((a, b) {
      final av = (a['deliveries'] as num?)?.toDouble() ?? 0;
      final bv = (b['deliveries'] as num?)?.toDouble() ?? 0;
      return bv.compareTo(av);
    });
    final top = drivers.take(limit).map((d) => {
          'id': d['id'],
          'name': d['displayName'] ?? d['name'] ?? 'Driver',
          'deliveries': d['deliveries'] ?? 0,
          'rating': d['rating'],
        }).toList();
    return ToolResult.ok(
      name,
      {
        'total': drivers.length,
        'online': online,
        'onDelivery': onDelivery,
        'idle': idle,
        'topPerformers': top,
      },
      summary:
          'Drivers: $online online, $onDelivery on delivery, $idle idle (of ${drivers.length}). Top: ${top.isNotEmpty ? top.first['name'] : 'n/a'} (${top.isNotEmpty ? top.first['deliveries'] : 0} deliveries).',
    );
  }
}

class AnalyzeStorePerformanceTool extends AgentTool {
  @override
  String get name => 'analyze_store_performance';
  @override
  String get description => 'Analyze store performance: revenue, order volume, ratings, cancellation rate.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'specific store (optional, default: top 10 overall)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final storeId = args['storeId'] as String?;

    if (storeId != null) {
      final orders = await db
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .limit(500)
          .get();
      int total = 0, cancelled = 0, delivered = 0;
      double revenue = 0;
      for (final doc in orders.docs) {
        final d = doc.data();
        total++;
        final status = d['status'] as String? ?? '';
        if (status == 'cancelled') cancelled++;
        if (status == 'delivered' || status == 'completed') {
          delivered++;
          revenue += (d['totalAmount'] as num?)?.toDouble() ?? 0;
        }
      }
      final cancelRate = total == 0 ? 0.0 : (cancelled / total) * 100;
      return ToolResult.ok(
        name,
        {
          'storeId': storeId,
          'orderCount': total,
          'delivered': delivered,
          'cancelled': cancelled,
          'cancellationRate': cancelRate,
          'revenue': revenue,
        },
        summary:
            'Store $storeId: $total orders, ${cancelRate.toStringAsFixed(1)}% cancel rate, \$${revenue.toStringAsFixed(0)} revenue.',
      );
    }

    final ordersSnap = await db
        .collection('orders')
        .where('status', whereIn: ['delivered', 'completed', 'cancelled'])
        .limit(1000)
        .get();
    final byStore = <String, Map<String, num>>{};
    for (final doc in ordersSnap.docs) {
      final d = doc.data();
      final sid = d['storeId'] as String? ?? 'unknown';
      final entry = byStore.putIfAbsent(sid, () => {'orders': 0, 'delivered': 0, 'cancelled': 0, 'revenue': 0});
      entry['orders'] = entry['orders']! + 1;
      final status = d['status'] as String? ?? '';
      if (status == 'cancelled') entry['cancelled'] = entry['cancelled']! + 1;
      if (status == 'delivered' || status == 'completed') {
        entry['delivered'] = entry['delivered']! + 1;
        entry['revenue'] = entry['revenue']! + ((d['totalAmount'] as num?)?.toDouble() ?? 0).toInt();
      }
    }
    final ranked = byStore.entries.toList()
      ..sort((a, b) => (b.value['revenue'] ?? 0).compareTo(a.value['revenue'] ?? 0));
    final top = ranked.take(10).map((e) => {
          'storeId': e.key,
          'revenue': e.value['revenue'],
          'orders': e.value['orders'],
          'cancellationRate':
              e.value['orders'] == 0 ? 0.0 : (e.value['cancelled']! / e.value['orders']!) * 100,
        }).toList();
    return ToolResult.ok(
      name,
      {'topStores': top, 'analyzedOrders': ordersSnap.size},
      summary: 'Analyzed ${ordersSnap.size} orders. Top store: \$${top.isNotEmpty ? top.first['revenue'] : 0}.',
    );
  }
}

class AnalyzeCustomerRetentionTool extends AgentTool {
  @override
  String get name => 'analyze_customer_retention';
  @override
  String get description => 'Analyze customer retention: active customers, repeat rate, top spenders, churned.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'window': 'week|month (default: month)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final window = (args['window'] as String?) ?? 'month';
    final days = window == 'week' ? 7 : 30;
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final cutoff = Timestamp.fromDate(now.subtract(Duration(days: days)));
    final priorCutoff = Timestamp.fromDate(now.subtract(Duration(days: days * 2)));

    final orders = await db
        .collection('orders')
        .where('createdAt', isGreaterThan: priorCutoff)
        .limit(2000)
        .get();
    final active = <String>{};
    final prior = <String>{};
    for (final doc in orders.docs) {
      final d = doc.data();
      final uid = d['userId'] as String? ?? d['customerId'] as String?;
      if (uid == null) continue;
      final ts = d['createdAt'];
      if (ts is Timestamp) {
        if (ts.compareTo(cutoff) > 0) {
          active.add(uid);
        } else {
          prior.add(uid);
        }
      }
    }
    final newCustomers = active.difference(prior).length;
    final retained = active.intersection(prior).length;
    final retention = active.isEmpty ? 0.0 : (retained / active.length) * 100;
    return ToolResult.ok(
      name,
      {
        'activeCustomers': active.length,
        'newCustomers': newCustomers,
        'retained': retained,
        'retentionRate': retention,
        'window': window,
      },
      summary:
          'Customers ($window): ${active.length} active, $newCustomers new, $retained retained. Retention: ${retention.toStringAsFixed(1)}%.',
    );
  }
}

class AnalyzeOrderTrendsTool extends AgentTool {
  @override
  String get name => 'analyze_order_trends';
  @override
  String get description => 'Analyze order trends: hourly heatmap, peak hours, day-of-week patterns, avg ticket size.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'days': 'history window in days (default 30)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final days = (args['days'] as int?) ?? 30;
    final db = FirebaseFirestore.instance;
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(Duration(days: days)));
    final snap = await db
        .collection('orders')
        .where('createdAt', isGreaterThan: cutoff)
        .limit(2000)
        .get();
    final byHour = List<int>.filled(24, 0);
    final byDow = List<int>.filled(7, 0);
    double total = 0;
    for (final doc in snap.docs) {
      final d = doc.data();
      total += (d['totalAmount'] as num?)?.toDouble() ?? 0;
      final ts = d['createdAt'];
      if (ts is Timestamp) {
        final dt = ts.toDate();
        byHour[dt.hour]++;
        byDow[dt.weekday - 1]++;
      }
    }
    final avgTicket = snap.size == 0 ? 0.0 : total / snap.size;
    int peakHour = 0;
    for (int i = 1; i < 24; i++) {
      if (byHour[i] > byHour[peakHour]) peakHour = i;
    }
    return ToolResult.ok(
      name,
      {
        'orders': snap.size,
        'avgTicket': avgTicket,
        'byHour': byHour,
        'byDow': byDow,
        'peakHour': peakHour,
      },
      summary:
          'Orders: ${snap.size} in $days days. Avg ticket \$${avgTicket.toStringAsFixed(2)}. Peak hour: $peakHour:00.',
    );
  }
}
