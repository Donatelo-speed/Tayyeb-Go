import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';

class ReadStoreTool extends AgentTool {
  @override
  String get name => 'read_store';
  @override
  String get description => 'Look up a single store by name or ID. Returns the full store document.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {'query': 'store name or ID'};

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final q = (args['query'] as String? ?? '').trim();
    if (q.isEmpty) return ToolResult.fail(name, 'Missing query');
    final db = FirebaseFirestore.instance;
    QuerySnapshot<Map<String, dynamic>> snap;
    if (q.length >= 20 && !q.contains(' ')) {
      final doc = await db.collection('restaurants').doc(q).get();
      if (!doc.exists) return ToolResult.fail(name, 'No store with ID $q');
      return ToolResult.ok(name, {'store': {...doc.data() ?? {}, 'id': doc.id}},
          summary: 'Loaded store "${(doc.data() ?? {})['name'] ?? q}".');
    }
    snap = await db
        .collection('restaurants')
        .where('name', isGreaterThanOrEqualTo: q)
        .where('name', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(5)
        .get();
    if (snap.docs.isEmpty) {
      snap = await db.collection('restaurants').orderBy('name').startAt([q]).endAt(['$q\uf8ff']).limit(5).get();
    }
    if (snap.docs.isEmpty) return ToolResult.fail(name, 'No store matches "$q"');
    final stores = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    return ToolResult.ok(name, {'stores': stores}, summary: 'Found ${stores.length} store(s) matching "$q".');
  }
}

class ListStoresTool extends AgentTool {
  @override
  String get name => 'list_stores';
  @override
  String get description => 'List all stores with optional filters (status, zone, category).';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'isActive': 'true|false (optional)',
        'businessStatus': 'open|busy|offline|suspended|pending_approval (optional)',
        'limit': 'max stores to return (default 50)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    Query<Map<String, dynamic>> q = db.collection('restaurants');
    final isActive = args['isActive'] as bool?;
    if (isActive != null) q = q.where('isActive', isEqualTo: isActive);
    final status = args['businessStatus'] as String?;
    if (status != null) q = q.where('businessStatus', isEqualTo: status);
    final limit = (args['limit'] as int?) ?? 50;
    final snap = await q.limit(limit).get();
    final stores = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    return ToolResult.ok(name, {'stores': stores, 'count': stores.length},
        summary: 'Listed ${stores.length} store(s).');
  }
}

class ListOrdersTool extends AgentTool {
  @override
  String get name => 'list_orders';
  @override
  String get description => 'List recent orders with optional filters (status, store, date range).';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'status': 'placed|accepted|preparing|ready|delivered|cancelled (optional)',
        'storeId': 'filter by store ID (optional)',
        'limit': 'max orders (default 30)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    Query<Map<String, dynamic>> q = db.collection('orders');
    final status = args['status'] as String?;
    if (status != null) q = q.where('status', isEqualTo: status);
    final storeId = args['storeId'] as String?;
    if (storeId != null) q = q.where('storeId', isEqualTo: storeId);
    final limit = (args['limit'] as int?) ?? 30;
    final snap = await q.orderBy('createdAt', descending: true).limit(limit).get();
    final orders = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    return ToolResult.ok(name, {'orders': orders, 'count': orders.length},
        summary: 'Loaded ${orders.length} order(s).');
  }
}

class ListDriversTool extends AgentTool {
  @override
  String get name => 'list_drivers';
  @override
  String get description => 'List drivers, optionally filtered by status (online, active, on_delivery, offline).';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'status': 'online|active|on_delivery|offline (optional)',
        'limit': 'max drivers (default 100)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    Query<Map<String, dynamic>> q = db.collection('users').where('role', isEqualTo: 'driver');
    final status = args['status'] as String?;
    if (status != null) q = q.where('status', isEqualTo: status);
    final limit = (args['limit'] as int?) ?? 100;
    final snap = await q.limit(limit).get();
    final drivers = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    return ToolResult.ok(name, {'drivers': drivers, 'count': drivers.length},
        summary: 'Loaded ${drivers.length} driver(s).');
  }
}

class ListCustomersTool extends AgentTool {
  @override
  String get name => 'list_customers';
  @override
  String get description => 'List customers, optionally filtered by recent activity or order count.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'minOrders': 'minimum order count (optional)',
        'limit': 'max customers (default 100)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final limit = (args['limit'] as int?) ?? 100;
    final snap = await db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .orderBy('orderCount', descending: true)
        .limit(limit)
        .get();
    final customers = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    return ToolResult.ok(name, {'customers': customers, 'count': customers.length},
        summary: 'Loaded ${customers.length} customer(s).');
  }
}

class ReadRevenueTool extends AgentTool {
  @override
  String get name => 'read_revenue';
  @override
  String get description => 'Compute revenue metrics: total today, last 7 days, by store, by category.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'window': 'today|week|month (default: today)',
        'storeId': 'optional store filter',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final window = (args['window'] as String?) ?? 'today';
    final storeId = args['storeId'] as String?;
    final now = DateTime.now();
    final cutoff = switch (window) {
      'week' => now.subtract(const Duration(days: 7)),
      'month' => now.subtract(const Duration(days: 30)),
      _ => DateTime(now.year, now.month, now.day),
    };

    Query<Map<String, dynamic>> q = db
        .collection('orders')
        .where('status', whereIn: ['delivered', 'completed'])
        .where('deliveredAt', isGreaterThan: Timestamp.fromDate(cutoff));
    if (storeId != null) q = q.where('storeId', isEqualTo: storeId);
    final snap = await q.limit(500).get();

    double total = 0;
    int count = 0;
    final byStore = <String, double>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final amt = (d['totalAmount'] as num?)?.toDouble() ?? 0;
      total += amt;
      count++;
      final sid = d['storeId'] as String? ?? 'unknown';
      byStore[sid] = (byStore[sid] ?? 0) + amt;
    }
    return ToolResult.ok(
      name,
      {
        'totalRevenue': total,
        'orderCount': count,
        'byStore': byStore,
        'window': window,
      },
      summary: 'Revenue ($window): \$${total.toStringAsFixed(0)} across $count orders.',
    );
  }
}

class ListNotificationsTool extends AgentTool {
  @override
  String get name => 'list_notifications';
  @override
  String get description => 'List recent platform notifications (announcements sent to users).';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'limit': 'max notifications (default 20)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final limit = (args['limit'] as int?) ?? 20;
    final snap = await db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    final notifs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    return ToolResult.ok(name, {'notifications': notifs, 'count': notifs.length},
        summary: 'Loaded ${notifs.length} notification(s).');
  }
}

class ReadSettingsTool extends AgentTool {
  @override
  String get name => 'read_settings';
  @override
  String get description => 'Read platform settings: feature flags, commission rates, service zones, app config.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, String> get parameterSchema => {
        'section': 'feature_flags|commissions|zones|app_config (optional, default: all)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final db = FirebaseFirestore.instance;
    final section = (args['section'] as String?) ?? 'all';
    if (section == 'feature_flags') {
      final snap = await db.collection('feature_flags').get();
      return ToolResult.ok(name, {'feature_flags': snap.docs.map((d) => {...d.data(), 'id': d.id}).toList()},
          summary: 'Loaded ${snap.size} feature flag(s).');
    }
    if (section == 'zones') {
      final snap = await db.collection('zones').get();
      return ToolResult.ok(name, {'zones': snap.docs.map((d) => {...d.data(), 'id': d.id}).toList()},
          summary: 'Loaded ${snap.size} zone(s).');
    }
    final snap = await db.collection('config').get();
    return ToolResult.ok(name, {'config': snap.docs.map((d) => {...d.data(), 'id': d.id}).toList()},
        summary: 'Loaded ${snap.size} config doc(s).');
  }
}
