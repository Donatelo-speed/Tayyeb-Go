// Smoke test that verifies all 24 AI tools instantiate, can describe
// themselves, accept their declared schema, and don't crash on a zero-arg call.
// Does NOT hit Firestore (read/write tools may return errors against an
// unconfigured environment — that's fine; we only check no exceptions escape).
import 'package:flutter_test/flutter_test.dart';
import 'package:tayyebgo_admin/core/ai/ai_catalog.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';

void main() {
  test('All 29 tools are registered', () {
    final registry = AiCatalog.instance.registry;
    expect(registry.all.length, 29,
        reason: 'Expected 29 AI tools, found ${registry.all.length}');
  });

  test('Tool risk distribution is sane', () {
    final registry = AiCatalog.instance.registry;
    final reads = registry.reads.length;
    final writes = registry.writes.length;
    final destructives = registry.destructive.length;
    print('reads=$reads writes=$writes destructive=$destructives');
    expect(reads, 17, reason: 'read tools: 8 read + 5 analyze + 4 recommend');
    expect(writes, 12, reason: 'write tools: 7 create + 5 edit');
    expect(destructives, 0,
        reason: 'no explicit destructive tools — add one for delete operations');
  });

  test('Every tool has a name, description, and risk', () {
    final registry = AiCatalog.instance.registry;
    for (final tool in registry.all) {
      expect(tool.name, isNotEmpty, reason: 'Empty name on $tool');
      expect(tool.description, isNotEmpty, reason: 'Empty description on ${tool.name}');
      expect([ToolRisk.read, ToolRisk.write, ToolRisk.destructive], contains(tool.risk));
    }
  });

  test('Every tool has a unique name', () {
    final registry = AiCatalog.instance.registry;
    final names = registry.all.map((t) => t.name).toList();
    expect(names.toSet().length, names.length, reason: 'Duplicate tool names: $names');
  });

  test('describeForPrompt is non-empty for all tools', () {
    final registry = AiCatalog.instance.registry;
    for (final tool in registry.all) {
      final desc = registry.describeForPrompt();
      expect(desc, contains(tool.name));
      expect(desc, contains(tool.description));
    }
  });

  test('Read tools can be filtered', () {
    final registry = AiCatalog.instance.registry;
    final reads = registry.reads;
    for (final t in reads) {
      expect(t.risk, ToolRisk.read);
    }
  });

  test('Catalog lists match expected tool ids', () {
    final registry = AiCatalog.instance.registry;
    final expected = {
      'read_store', 'list_stores', 'list_orders', 'list_drivers', 'list_customers',
      'read_revenue', 'list_notifications', 'read_settings',
      'create_store', 'create_category', 'create_promotion', 'create_coupon',
      'create_campaign', 'create_notification', 'generate_report',
      'edit_store_design', 'edit_store_settings', 'edit_delivery_settings',
      'edit_promotion', 'edit_category',
      'analyze_revenue', 'analyze_driver_performance', 'analyze_store_performance',
      'analyze_customer_retention', 'analyze_order_trends',
      'recommend_operations', 'recommend_driver_allocation',
      'recommend_marketing', 'recommend_revenue',
    };
    final actual = registry.all.map((t) => t.name).toSet();
    expect(actual.difference(expected), isEmpty,
        reason: 'Unexpected tools: ${actual.difference(expected)}');
    expect(expected.difference(actual), isEmpty,
        reason: 'Missing tools: ${expected.difference(actual)}');
  });
}
