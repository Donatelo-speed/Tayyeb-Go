import 'package:flutter/foundation.dart';

enum ToolRisk { read, write, destructive }

@immutable
class ToolCall {
  final String toolName;
  final Map<String, dynamic> arguments;
  final ToolRisk risk;
  final String? humanLabel;
  const ToolCall({
    required this.toolName,
    required this.arguments,
    required this.risk,
    this.humanLabel,
  });
}

@immutable
class ToolResult {
  final String toolName;
  final bool success;
  final Map<String, dynamic> data;
  final String? error;
  final String? humanSummary;
  const ToolResult({
    required this.toolName,
    required this.success,
    this.data = const {},
    this.error,
    this.humanSummary,
  });

  factory ToolResult.ok(String tool, Map<String, dynamic> data, {String? summary}) =>
      ToolResult(toolName: tool, success: true, data: data, humanSummary: summary);

  factory ToolResult.fail(String tool, String error) =>
      ToolResult(toolName: tool, success: false, error: error);
}

enum AgentMessageRole { user, assistant, system, tool }

@immutable
class AgentMessage {
  final AgentMessageRole role;
  final String content;
  final List<ToolCall> toolCalls;
  final List<ToolResult> toolResults;
  final String? plan;
  final DateTime timestamp;

  AgentMessage({
    required this.role,
    required this.content,
    this.toolCalls = const [],
    this.toolResults = const [],
    this.plan,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  AgentMessage copyWith({
    AgentMessageRole? role,
    String? content,
    List<ToolCall>? toolCalls,
    List<ToolResult>? toolResults,
    String? plan,
  }) {
    return AgentMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      toolCalls: toolCalls ?? this.toolCalls,
      toolResults: toolResults ?? this.toolResults,
      plan: plan ?? this.plan,
    );
  }
}
