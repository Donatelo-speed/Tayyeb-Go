import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';

class CreateStoreTool extends AgentTool {
  @override
  String get name => 'create_store';
  @override
  String get description => 'Create a new store/business (draft by default, not yet active). Returns the new store ID.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'name': 'store name (required)',
        'businessType': 'restaurant|pharmacy|cafe|... (required)',
        'category': 'food|retail|service (required)',
        'ownerId': 'owner user ID (required)',
        'template': 'modern|minimal|premium|market|pharmacy|cafe|... (optional)',
        'zone': 'zone ID (optional)',
        'phone': 'phone (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final name = (args['name'] as String? ?? '').trim();
    if (name.isEmpty) return ToolResult.fail(name, 'Missing name');
    final businessType = (args['businessType'] as String? ?? '').trim();
    if (businessType.isEmpty) return ToolResult.fail(name, 'Missing businessType');
    final category = (args['category'] as String? ?? 'food').trim();
    final ownerId = (args['ownerId'] as String? ?? '').trim();

    final db = FirebaseFirestore.instance;
    final ref = await db.collection('Restaurants').add({
      'name': name,
      'businessType': businessType,
      'businessCategory': category,
      'ownerId': ownerId,
      'designTemplate': args['template'] ?? 'modern',
      'phone': args['phone'] ?? '',
      'zone': args['zone'],
      'isActive': false,
      'businessStatus': 'pending_approval',
      'deliveryMode': 'platform_only',
      'commissionPercent': 15.0,
      'rating': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ToolResult.ok(
      name,
      {'storeId': ref.id, 'name': name},
      summary: 'Created store "$name" (draft, awaiting approval).',
    );
  }
}

class CreateCategoryTool extends AgentTool {
  @override
  String get name => 'create_category';
  @override
  String get description => 'Create a menu category inside a store. Categories organize products.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'store ID (required)',
        'name': 'category name (required)',
        'icon': 'icon key (optional)',
        'order': 'display order (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final storeId = args['storeId'] as String?;
    final name = (args['name'] as String? ?? '').trim();
    if (storeId == null || name.isEmpty) {
      return ToolResult.fail(name, 'Missing storeId or name');
    }
    final db = FirebaseFirestore.instance;
    final ref = await db
        .collection('Restaurants')
        .doc(storeId)
        .collection('categories')
        .add({
      'name': name,
      'icon': args['icon'],
      'order': args['order'] ?? 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ToolResult.ok(name, {'categoryId': ref.id},
        summary: 'Created category "$name" in store $storeId.');
  }
}

class CreatePromotionTool extends AgentTool {
  @override
  String get name => 'create_promotion';
  @override
  String get description => 'Create a store-level promotion (percentage off, fixed off, BOGO, etc).';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'store ID (required)',
        'title': 'promo title (required)',
        'type': 'percentage|fixed|bogo|free_delivery (required)',
        'value': 'numeric value (percentage or amount)',
        'minOrder': 'minimum order amount (optional)',
        'expiresAt': 'ISO date string (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final storeId = args['storeId'] as String?;
    final title = (args['title'] as String? ?? '').trim();
    final type = args['type'] as String?;
    if (storeId == null || title.isEmpty || type == null) {
      return ToolResult.fail(name, 'Missing storeId, title, or type');
    }
    final db = FirebaseFirestore.instance;
    final ref = await db
        .collection('Restaurants')
        .doc(storeId)
        .collection('promotions')
        .add({
      'title': title,
      'type': type,
      'value': (args['value'] as num?)?.toDouble() ?? 0,
      'minOrder': (args['minOrder'] as num?)?.toDouble() ?? 0,
      'expiresAt': args['expiresAt'] != null
          ? Timestamp.fromDate(DateTime.parse(args['expiresAt'] as String))
          : null,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ToolResult.ok(name, {'promotionId': ref.id},
        summary: 'Created promotion "$title" in store $storeId.');
  }
}

class CreateCouponTool extends AgentTool {
  @override
  String get name => 'create_coupon';
  @override
  String get description => 'Create a platform-wide coupon code customers can redeem.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'code': 'coupon code (required, uppercased)',
        'type': 'percentage|fixed|free_delivery (required)',
        'value': 'numeric value (required)',
        'minOrder': 'minimum order amount (optional)',
        'usageLimit': 'max total redemptions (optional)',
        'expiresAt': 'ISO date (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final code = (args['code'] as String? ?? '').trim().toUpperCase();
    final type = args['type'] as String?;
    final value = (args['value'] as num?)?.toDouble();
    if (code.isEmpty || type == null || value == null) {
      return ToolResult.fail(name, 'Missing code, type, or value');
    }
    final db = FirebaseFirestore.instance;
    final ref = await db.collection('coupons').add({
      'code': code,
      'type': type,
      'value': value,
      'minOrder': (args['minOrder'] as num?)?.toDouble() ?? 0,
      'usageLimit': (args['usageLimit'] as int?) ?? 0,
      'usageCount': 0,
      'isActive': true,
      'expiresAt': args['expiresAt'] != null
          ? Timestamp.fromDate(DateTime.parse(args['expiresAt'] as String))
          : null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ToolResult.ok(name, {'couponId': ref.id, 'code': code},
        summary: 'Created coupon $code.');
  }
}

class CreateCampaignTool extends AgentTool {
  @override
  String get name => 'create_campaign';
  @override
  String get description => 'Create a marketing campaign (with audience, channels, schedule).';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'name': 'campaign name (required)',
        'audience': 'all|new_users|churned|drivers|stores|zone_X (required)',
        'channel': 'push|email|sms|in_app (required)',
        'message': 'campaign message (required)',
        'startsAt': 'ISO date (optional)',
        'endsAt': 'ISO date (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final name = (args['name'] as String? ?? '').trim();
    final audience = args['audience'] as String?;
    final channel = args['channel'] as String?;
    final message = args['message'] as String?;
    if (name.isEmpty || audience == null || channel == null || message == null) {
      return ToolResult.fail(name, 'Missing name, audience, channel, or message');
    }
    final db = FirebaseFirestore.instance;
    final ref = await db.collection('campaigns').add({
      'name': name,
      'audience': audience,
      'channel': channel,
      'message': message,
      'startsAt': args['startsAt'] != null
          ? Timestamp.fromDate(DateTime.parse(args['startsAt'] as String))
          : null,
      'endsAt': args['endsAt'] != null
          ? Timestamp.fromDate(DateTime.parse(args['endsAt'] as String))
          : null,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ToolResult.ok(name, {'campaignId': ref.id},
        summary: 'Created campaign "$name" (audience: $audience, channel: $channel).');
  }
}

class CreateNotificationTool extends AgentTool {
  @override
  String get name => 'create_notification';
  @override
  String get description => 'Send a notification to a user, a group, or a zone.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'title': 'notification title (required)',
        'body': 'notification body (required)',
        'audience': 'user:<id> | role:customer|driver|store | zone:<id> | all (required)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final title = (args['title'] as String? ?? '').trim();
    final body = (args['body'] as String? ?? '').trim();
    final audience = args['audience'] as String?;
    if (title.isEmpty || body.isEmpty || audience == null) {
      return ToolResult.fail(name, 'Missing title, body, or audience');
    }
    final db = FirebaseFirestore.instance;
    final ref = await db.collection('notifications').add({
      'title': title,
      'body': body,
      'audience': audience,
      'sentBy': 'ai_copilot',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ToolResult.ok(name, {'notificationId': ref.id},
        summary: 'Sent notification "$title" to $audience.');
  }
}

class GenerateReportTool extends AgentTool {
  @override
  String get name => 'generate_report';
  @override
  String get description => 'Generate a one-time report document and store it in the reports collection.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'type': 'revenue|orders|drivers|stores|overview (required)',
        'window': 'today|week|month (default: week)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final type = args['type'] as String?;
    if (type == null) return ToolResult.fail(name, 'Missing type');
    final window = (args['window'] as String?) ?? 'week';
    final db = FirebaseFirestore.instance;
    final ref = await db.collection('reports').add({
      'type': type,
      'window': window,
      'generatedBy': 'ai_copilot',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    return ToolResult.ok(name, {'reportId': ref.id},
        summary: 'Queued $type report ($window). Will appear in the Reports tab.');
  }
}
