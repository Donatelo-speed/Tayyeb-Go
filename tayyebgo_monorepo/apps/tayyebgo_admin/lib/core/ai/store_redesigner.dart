import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';
import 'package:tayyebgo_admin/core/ai/ai_catalog.dart';

class RedesignPlan {
  final String storeId;
  final String storeName;
  final String fromTemplate;
  final String toTemplate;
  final String? primaryColor;
  final String? accentColor;
  final String? banner;
  final List<String> newSections;
  final List<String> improvements;

  const RedesignPlan({
    required this.storeId,
    required this.storeName,
    required this.fromTemplate,
    required this.toTemplate,
    this.primaryColor,
    this.accentColor,
    this.banner,
    this.newSections = const [],
    this.improvements = const [],
  });

  String summarize() {
    final parts = <String>[
      'Store: $storeName',
      'Template: $fromTemplate → $toTemplate',
      if (primaryColor != null) 'Primary: $primaryColor',
      if (accentColor != null) 'Accent: $accentColor',
      if (banner != null) 'Banner: $banner',
      if (newSections.isNotEmpty) 'Sections: ${newSections.join(", ")}',
      if (improvements.isNotEmpty) '\nImprovements:\n • ${improvements.join("\n • ")}',
    ];
    return parts.join('\n');
  }
}

class StoreRedesigner {
  final AgentToolRegistry _registry = AiCatalog.instance.registry;

  Future<RedesignPlan> suggest(String storeName) async {
    final read = await _registry.get('read_store')!.execute({'query': storeName});
    if (!read.success || read.data['stores'] == null) {
      throw Exception('Could not find store "$storeName".');
    }
    final stores = (read.data['stores'] as List).cast<Map<String, dynamic>>();
    if (stores.isEmpty) {
      throw Exception('No store matches "$storeName".');
    }
    final store = stores.first;
    final id = store['id'] as String;
    final fromTemplate = (store['designTemplate'] as String?) ?? 'modern';
    final toTemplate = _upgradeTemplate(fromTemplate);

    final improvements = <String>[];
    if ((store['bannerText'] as String?) == null) {
      improvements.add('Add a hero banner to greet customers.');
    }
    if ((store['logoUrl'] as String?) == null) {
      improvements.add('Upload a logo to lift brand recognition.');
    }
    if (((store['homepageSections'] as List?)?.isEmpty ?? true)) {
      improvements.add('Promote featured products, promotions, and a "new arrivals" rail.');
    }
    if ((store['rating'] as num?)?.toDouble() == 0) {
      improvements.add('Add reviews to build social proof.');
    }
    if ((store['commissionPercent'] as num?)?.toDouble() == 15.0) {
      improvements.add('Reassess commission tier based on order volume.');
    }

    final newSections = const ['hero', 'featured', 'promotions', 'new_arrivals', 'reviews', 'about'];
    return RedesignPlan(
      storeId: id,
      storeName: store['name'] as String? ?? storeName,
      fromTemplate: fromTemplate,
      toTemplate: toTemplate,
      primaryColor: _nextColor(fromTemplate, toTemplate),
      accentColor: _nextAccent(toTemplate),
      banner: 'Welcome back — we just got better.',
      newSections: newSections,
      improvements: improvements,
    );
  }

  List<ToolCall> apply(RedesignPlan plan) {
    return [
      ToolCall(
        toolName: 'edit_store_design',
        arguments: {
          'storeId': plan.storeId,
          'template': plan.toTemplate,
          'primaryColor': plan.primaryColor,
          'accentColor': plan.accentColor,
          'banner': plan.banner,
          'sections': plan.newSections.join(','),
        },
        risk: ToolRisk.write,
        humanLabel: 'Apply new design (${plan.fromTemplate} → ${plan.toTemplate})',
      ),
    ];
  }

  String _upgradeTemplate(String from) {
    const ladder = ['modern', 'minimal', 'cafe', 'restaurant', 'fast_food', 'market', 'pharmacy', 'premium'];
    final idx = ladder.indexOf(from);
    if (idx == -1 || idx == ladder.length - 1) return 'premium';
    return ladder[idx + 1];
  }

  String? _nextColor(String from, String to) {
    const palette = {
      'modern': '#1D4ED8',
      'minimal': '#0F172A',
      'cafe': '#7C3AED',
      'restaurant': '#F97316',
      'fast_food': '#EF4444',
      'market': '#059669',
      'pharmacy': '#0EA5E9',
      'premium': '#111827',
    };
    return palette[to];
  }

  String? _nextAccent(String to) {
    const accents = {
      'modern': '#3B82F6',
      'minimal': '#64748B',
      'cafe': '#F472B6',
      'restaurant': '#DC2626',
      'fast_food': '#F59E0B',
      'market': '#FACC15',
      'pharmacy': '#22D3EE',
      'premium': '#F59E0B',
    };
    return accents[to];
  }
}
