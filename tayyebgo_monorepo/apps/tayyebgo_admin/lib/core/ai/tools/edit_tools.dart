import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';

class EditStoreDesignTool extends AgentTool {
  @override
  String get name => 'edit_store_design';
  @override
  String get description => 'Edit a store\'s design: template, color theme, banner, hero, sections, featured items.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'store ID (required)',
        'template': 'modern|minimal|premium|market|pharmacy|cafe|fast_food|restaurant (optional)',
        'primaryColor': 'hex color, e.g. #1D4ED8 (optional)',
        'accentColor': 'hex color (optional)',
        'banner': 'banner text (optional)',
        'sections': 'comma-separated section ids, e.g. featured,promotions,new (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final storeId = args['storeId'] as String?;
    if (storeId == null) return ToolResult.fail(name, 'Missing storeId');
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (args['template'] != null) updates['designTemplate'] = args['template'];
    if (args['primaryColor'] != null) updates['themePrimary'] = args['primaryColor'];
    if (args['accentColor'] != null) updates['themeAccent'] = args['accentColor'];
    if (args['banner'] != null) updates['bannerText'] = args['banner'];
    if (args['sections'] != null) {
      updates['homepageSections'] =
          (args['sections'] as String).split(',').map((s) => s.trim()).toList();
    }
    if (updates.length == 1) {
      return ToolResult.fail(name, 'No design changes provided');
    }
    await FirebaseFirestore.instance.collection('Restaurants').doc(storeId).update(updates);
    return ToolResult.ok(name, {'updated': updates.keys.toList()},
        summary: 'Updated ${updates.length - 1} design field(s) on store $storeId.');
  }
}

class EditStoreSettingsTool extends AgentTool {
  @override
  String get name => 'edit_store_settings';
  @override
  String get description => 'Edit operational store settings: name, phone, address, commission, category, isActive.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'store ID (required)',
        'name': 'new name (optional)',
        'phone': 'new phone (optional)',
        'street': 'street address (optional)',
        'city': 'city (optional)',
        'commissionPercent': 'number 0-50 (optional)',
        'isActive': 'true|false (optional)',
        'businessStatus': 'open|busy|offline|suspended|pending_approval (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final storeId = args['storeId'] as String?;
    if (storeId == null) return ToolResult.fail(name, 'Missing storeId');
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    void setIfPresent(String key) {
      if (args.containsKey(key) && args[key] != null) updates[key] = args[key];
    }

    setIfPresent('name');
    setIfPresent('phone');
    setIfPresent('street');
    setIfPresent('city');
    setIfPresent('businessStatus');
    if (args['commissionPercent'] is num) {
      updates['commissionPercent'] = (args['commissionPercent'] as num).toDouble();
    }
    if (args['isActive'] is bool) updates['isActive'] = args['isActive'];
    if (updates.length == 1) return ToolResult.fail(name, 'No settings provided');
    await FirebaseFirestore.instance.collection('Restaurants').doc(storeId).update(updates);
    return ToolResult.ok(name, {'updated': updates.keys.toList()},
        summary: 'Updated ${updates.length - 1} setting(s) on store $storeId.');
  }
}

class EditDeliverySettingsTool extends AgentTool {
  @override
  String get name => 'edit_delivery_settings';
  @override
  String get description => 'Edit delivery mode and fallback behavior for a store.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'store ID (required)',
        'deliveryMode': 'store_only|platform_only|hybrid (required)',
        'allowPlatformFallback': 'true|false (optional, for hybrid)',
        'fallbackDelaySeconds': 'number 0-300 (optional, for hybrid)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final storeId = args['storeId'] as String?;
    final mode = args['deliveryMode'] as String?;
    if (storeId == null || mode == null) {
      return ToolResult.fail(name, 'Missing storeId or deliveryMode');
    }
    final updates = <String, dynamic>{
      'deliveryMode': mode,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (mode == 'hybrid') {
      if (args['allowPlatformFallback'] is bool) {
        updates['allowPlatformFallback'] = args['allowPlatformFallback'];
      }
      if (args['fallbackDelaySeconds'] is num) {
        updates['fallbackDelaySeconds'] = (args['fallbackDelaySeconds'] as num).toInt();
      }
    }
    await FirebaseFirestore.instance.collection('Restaurants').doc(storeId).update(updates);
    return ToolResult.ok(name, {'mode': mode},
        summary: 'Set delivery mode to $mode for store $storeId.');
  }
}

class EditPromotionTool extends AgentTool {
  @override
  String get name => 'edit_promotion';
  @override
  String get description => 'Edit or disable a promotion.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'store ID (required)',
        'promotionId': 'promotion ID (required)',
        'title': 'new title (optional)',
        'value': 'new value (optional)',
        'isActive': 'true|false (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final storeId = args['storeId'] as String?;
    final promoId = args['promotionId'] as String?;
    if (storeId == null || promoId == null) {
      return ToolResult.fail(name, 'Missing storeId or promotionId');
    }
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (args['title'] is String) updates['title'] = args['title'];
    if (args['value'] is num) updates['value'] = (args['value'] as num).toDouble();
    if (args['isActive'] is bool) updates['isActive'] = args['isActive'];
    if (updates.length == 1) return ToolResult.fail(name, 'Nothing to update');
    await FirebaseFirestore.instance
        .collection('Restaurants')
        .doc(storeId)
        .collection('promotions')
        .doc(promoId)
        .update(updates);
    return ToolResult.ok(name, {'updated': updates.keys.toList()},
        summary: 'Updated promotion $promoId.');
  }
}

class EditCategoryTool extends AgentTool {
  @override
  String get name => 'edit_category';
  @override
  String get description => 'Edit or reorder a category inside a store.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, String> get parameterSchema => {
        'storeId': 'store ID (required)',
        'categoryId': 'category ID (required)',
        'name': 'new name (optional)',
        'order': 'new display order (optional)',
        'isActive': 'true|false (optional)',
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final storeId = args['storeId'] as String?;
    final catId = args['categoryId'] as String?;
    if (storeId == null || catId == null) {
      return ToolResult.fail(name, 'Missing storeId or categoryId');
    }
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (args['name'] is String) updates['name'] = args['name'];
    if (args['order'] is num) updates['order'] = (args['order'] as num).toInt();
    if (args['isActive'] is bool) updates['isActive'] = args['isActive'];
    if (updates.length == 1) return ToolResult.fail(name, 'Nothing to update');
    await FirebaseFirestore.instance
        .collection('Restaurants')
        .doc(storeId)
        .collection('categories')
        .doc(catId)
        .update(updates);
    return ToolResult.ok(name, {'updated': updates.keys.toList()},
        summary: 'Updated category $catId.');
  }
}
