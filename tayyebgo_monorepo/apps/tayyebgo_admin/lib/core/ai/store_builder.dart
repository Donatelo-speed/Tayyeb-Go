import 'package:tayyebgo_admin/core/ai/agent_types.dart';
import 'package:tayyebgo_admin/core/ai/argument_extractor.dart';

class BuildPlan {
  final String storeName;
  final String businessType;
  final String? category;
  final String template;
  final List<String> categories;
  final String? primaryColor;
  final String? accentColor;
  final String? banner;
  final List<String> sections;
  final String deliveryMode;
  final bool platformFallback;
  final int fallbackDelaySeconds;
  final double commissionPercent;

  const BuildPlan({
    required this.storeName,
    required this.businessType,
    required this.template,
    required this.categories,
    required this.deliveryMode,
    required this.platformFallback,
    required this.fallbackDelaySeconds,
    required this.commissionPercent,
    this.category,
    this.primaryColor,
    this.accentColor,
    this.banner,
    this.sections = const ['featured', 'categories', 'promotions', 'new_arrivals'],
  });

  String summarize() {
    final parts = <String>[
      'Name: $storeName',
      'Type: $businessType',
      'Template: $template',
      'Categories: ${categories.join(", ")}',
      'Delivery: $deliveryMode${platformFallback ? " (fallback ${fallbackDelaySeconds}s)" : ""}',
      'Commission: ${commissionPercent.toStringAsFixed(0)}%',
      'Sections: ${sections.join(", ")}',
    ];
    return parts.join('\n');
  }
}

class StoreBuilder {
  BuildPlan planFromInput(String input, {String ownerId = 'pending_owner'}) {
    final name = ArgumentExtractor.entityName(input) ?? 'New Store';
    final type = ArgumentExtractor.businessType(input) ?? 'restaurant';
    final template = ArgumentExtractor.template(input) ?? _defaultTemplateFor(type);
    final color = ArgumentExtractor.hexColor(input);

    return BuildPlan(
      storeName: name,
      businessType: type,
      category: _categoryFor(type),
      template: template,
      categories: _defaultCategoriesFor(type),
      primaryColor: color ?? _defaultColorFor(template),
      accentColor: _defaultAccentFor(template),
      banner: _defaultBannerFor(name, type),
      deliveryMode: 'platform_only',
      platformFallback: true,
      fallbackDelaySeconds: 30,
      commissionPercent: 15.0,
    );
  }

  /// Translates a plan into the sequence of tool calls the agent will execute.
  List<ToolCall> callsFor(BuildPlan plan, {String ownerId = 'pending_owner'}) {
    final calls = <ToolCall>[];

    // 1. Create the store
    calls.add(ToolCall(
      toolName: 'create_store',
      arguments: {
        'name': plan.storeName,
        'businessType': plan.businessType,
        'category': plan.category ?? 'food',
        'ownerId': ownerId,
        'template': plan.template,
        'phone': '',
      },
      risk: ToolRisk.write,
      humanLabel: 'Create draft store "${plan.storeName}"',
    ));

    // The store ID comes from the first tool result. We capture it at
    // execution time via the orchestrator.
    for (final cat in plan.categories) {
      calls.add(ToolCall(
        toolName: 'create_category',
        arguments: {'storeId': '__STORE_ID__', 'name': cat},
        risk: ToolRisk.write,
        humanLabel: 'Add category "$cat"',
      ));
    }

    // 2. Design + delivery settings
    calls.add(ToolCall(
      toolName: 'edit_store_design',
      arguments: {
        'storeId': '__STORE_ID__',
        'template': plan.template,
        'primaryColor': plan.primaryColor,
        'accentColor': plan.accentColor,
        'banner': plan.banner,
        'sections': plan.sections.join(','),
      },
      risk: ToolRisk.write,
      humanLabel: 'Apply design template + sections',
    ));

    calls.add(ToolCall(
      toolName: 'edit_delivery_settings',
      arguments: {
        'storeId': '__STORE_ID__',
        'deliveryMode': plan.deliveryMode,
        'allowPlatformFallback': plan.platformFallback,
        'fallbackDelaySeconds': plan.fallbackDelaySeconds,
      },
      risk: ToolRisk.write,
      humanLabel: 'Configure delivery (${plan.deliveryMode})',
    ));

    return calls;
  }

  String _defaultTemplateFor(String type) {
    switch (type) {
      case 'pharmacy':
        return 'pharmacy';
      case 'cafe':
        return 'cafe';
      case 'market':
        return 'market';
      case 'fast_food':
        return 'fast_food';
      case 'restaurant':
        return 'restaurant';
      case 'electronics':
        return 'modern';
      default:
        return 'modern';
    }
  }

  String _categoryFor(String type) {
    if (type == 'pharmacy') return 'health';
    if (type == 'market' || type == 'retail' || type == 'electronics') return 'retail';
    if (type == 'service') return 'service';
    return 'food';
  }

  List<String> _defaultCategoriesFor(String type) {
    switch (type) {
      case 'pharmacy':
        return ['Medicines', 'Personal Care', 'Vitamins', 'Baby Care', 'Devices'];
      case 'cafe':
        return ['Hot Coffee', 'Cold Brew', 'Pastries', 'Sandwiches', 'Specials'];
      case 'market':
        return ['Fruits & Veg', 'Dairy', 'Bakery', 'Beverages', 'Snacks'];
      case 'fast_food':
        return ['Burgers', 'Sides', 'Drinks', 'Combos', 'Desserts'];
      case 'restaurant':
        return ['Starters', 'Mains', 'Pizzas', 'Drinks', 'Desserts'];
      case 'electronics':
        return ['Phones', 'Laptops', 'Accessories', 'Audio', 'Deals'];
      default:
        return ['Featured', 'Popular', 'New', 'Promotions'];
    }
  }

  String _defaultColorFor(String template) {
    switch (template) {
      case 'pharmacy':
        return '#0EA5E9';
      case 'cafe':
        return '#7C3AED';
      case 'market':
        return '#059669';
      case 'fast_food':
        return '#EF4444';
      case 'restaurant':
        return '#F97316';
      case 'premium':
        return '#1F2937';
      default:
        return '#1D4ED8';
    }
  }

  String _defaultAccentFor(String template) {
    switch (template) {
      case 'pharmacy':
        return '#22D3EE';
      case 'cafe':
        return '#F472B6';
      case 'market':
        return '#FACC15';
      case 'fast_food':
        return '#F59E0B';
      case 'restaurant':
        return '#DC2626';
      case 'premium':
        return '#F59E0B';
      default:
        return '#3B82F6';
    }
  }

  String? _defaultBannerFor(String name, String type) {
    return 'Welcome to $name — fresh, fast, delivered.';
  }
}
