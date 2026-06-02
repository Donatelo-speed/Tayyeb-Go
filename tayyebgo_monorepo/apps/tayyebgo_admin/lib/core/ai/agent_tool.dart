import 'package:flutter/foundation.dart';
import 'agent_types.dart';

/// Contract every AI tool must satisfy.
abstract class AgentTool {
  String get name;
  String get description;
  ToolRisk get risk;
  Map<String, String> get parameterSchema;
  Future<ToolResult> execute(Map<String, dynamic> arguments);
}

class AgentToolRegistry {
  final Map<String, AgentTool> _tools = {};
  void register(AgentTool tool) {
    _tools[tool.name] = tool;
  }

  AgentTool? get(String name) => _tools[name];

  Iterable<AgentTool> get all => _tools.values;
  List<AgentTool> get reads => _tools.values.where((t) => t.risk == ToolRisk.read).toList();
  List<AgentTool> get writes => _tools.values.where((t) => t.risk == ToolRisk.write).toList();
  List<AgentTool> get destructive =>
      _tools.values.where((t) => t.risk == ToolRisk.destructive).toList();

  String describeForPrompt() {
    return _tools.values
        .map((t) =>
            '- ${t.name} (${t.risk.name}): ${t.description}\n   args: ${t.parameterSchema.entries.map((e) => '${e.key}: ${e.value}').join(', ')}')
        .join('\n');
  }
}

@immutable
class ToolInvocation {
  final String toolName;
  final Map<String, dynamic> arguments;
  const ToolInvocation(this.toolName, this.arguments);
}
