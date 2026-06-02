import 'dart:async';
import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';
import 'package:tayyebgo_admin/core/ai/ai_catalog.dart';
import 'package:tayyebgo_admin/core/ai/argument_extractor.dart';
import 'package:tayyebgo_admin/core/ai/intent_classifier.dart';
import 'package:tayyebgo_admin/core/ai/store_builder.dart';
import 'package:tayyebgo_admin/core/ai/store_redesigner.dart';

enum AgentStatus { idle, planning, awaitingConfirmation, executing, done, error }

class AgentState {
  final List<AgentMessage> messages;
  final AgentStatus status;
  final String? error;
  final List<ToolCall> pendingPlan;

  const AgentState({
    this.messages = const [],
    this.status = AgentStatus.idle,
    this.error,
    this.pendingPlan = const [],
  });

  AgentState copyWith({
    List<AgentMessage>? messages,
    AgentStatus? status,
    String? error,
    List<ToolCall>? pendingPlan,
  }) {
    return AgentState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      error: error ?? this.error,
      pendingPlan: pendingPlan ?? this.pendingPlan,
    );
  }
}

class CopilotEvent {
  final AgentState state;
  const CopilotEvent(this.state);
}

class AiCopilot {
  final AgentToolRegistry _registry = AiCatalog.instance.registry;
  final StoreBuilder _builder = StoreBuilder();
  final StoreRedesigner _redesigner = StoreRedesigner();

  AgentState _state = AgentState(
    messages: [
      AgentMessage(
        role: AgentMessageRole.system,
        content:
            'You are TayyebGo Copilot — an operations manager, business analyst, marketing assistant, and store designer for the platform. You read live data, you take action, and you propose plans that the admin approves.',
      ),
      AgentMessage(
        role: AgentMessageRole.assistant,
        content:
            "Hi — I'm Copilot. I can read live data, run analyses, draft campaigns, build stores, and redesign existing ones. What should I do?",
      ),
    ],
  );

  AgentState get state => _state;

  /// Resets the session (keeps the system prompt + greeting).
  void reset() {
    _state = AgentState(messages: _state.messages.sublist(0, 2));
  }

  /// User submitted a message. Builds a plan and either executes read-only
  /// tools directly or returns a plan for confirmation.
  Future<void> submit(String input) async {
    final userMsg = AgentMessage(role: AgentMessageRole.user, content: input);
    _state = _state.copyWith(
      messages: [..._state.messages, userMsg],
      status: AgentStatus.planning,
    );

    try {
      final intent = IntentClassifier.classify(input);
      if (intent == null) {
        _state = _state.copyWith(
          messages: [
            ..._state.messages,
            AgentMessage(
              role: AgentMessageRole.assistant,
              content: "I'm not sure what to do with that. Try asking about stores, drivers, revenue, retention, or say 'create a pharmacy called Al Shifa'.",
            ),
          ],
          status: AgentStatus.idle,
        );
        return;
      }

      // Build a plan
      final planCalls = _planForIntent(intent, input);
      if (planCalls.isEmpty) {
        _state = _state.copyWith(
          messages: [
            ..._state.messages,
            AgentMessage(
              role: AgentMessageRole.assistant,
              content: "I can do that, but I need a bit more info. ${intent.clarifyingQuestion ?? "What store name should I use?"}",
            ),
          ],
          status: AgentStatus.idle,
        );
        return;
      }

      final isReadOnly = planCalls.every((c) => c.risk == ToolRisk.read);

      if (isReadOnly) {
        await _execute(planCalls, intent);
      } else {
        _state = _state.copyWith(
          messages: [
            ..._state.messages,
            AgentMessage(
              role: AgentMessageRole.assistant,
              content: _planSummary(intent, planCalls),
              plan: _planSummary(intent, planCalls),
            ),
          ],
          pendingPlan: planCalls,
          status: AgentStatus.awaitingConfirmation,
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        messages: [
          ..._state.messages,
          AgentMessage(
            role: AgentMessageRole.assistant,
            content: 'Something went wrong: $e',
          ),
        ],
        status: AgentStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Confirm and execute the pending plan.
  Future<void> confirmPlan() async {
    final calls = _state.pendingPlan;
    if (calls.isEmpty) return;
    _state = _state.copyWith(
      status: AgentStatus.executing,
      pendingPlan: const [],
    );
    final intent = IntentClassifier.classify(_lastUserInput() ?? '');
    await _execute(calls, intent);
  }

  /// Reject the pending plan.
  void rejectPlan() {
    _state = _state.copyWith(
      messages: [
        ..._state.messages,
        AgentMessage(
          role: AgentMessageRole.assistant,
          content: "No problem. Tell me what you'd like to change.",
        ),
      ],
      pendingPlan: const [],
      status: AgentStatus.idle,
    );
  }

  Future<void> _execute(List<ToolCall> calls, Intent? intent) async {
    String? storeIdFromCreate;
    final results = <ToolResult>[];
    for (final call in calls) {
      final args = Map<String, dynamic>.from(call.arguments);
      if (args['storeId'] == '__STORE_ID__') {
        if (storeIdFromCreate == null) {
          results.add(ToolResult.fail(call.toolName, 'No store ID available from prior step.'));
          continue;
        }
        args['storeId'] = storeIdFromCreate;
      }
      final tool = _registry.get(call.toolName);
      if (tool == null) {
        results.add(ToolResult.fail(call.toolName, 'Tool not registered.'));
        continue;
      }
      try {
        final result = await tool.execute(args);
        results.add(result);
        if (call.toolName == 'create_store' && result.success) {
          storeIdFromCreate = result.data['storeId'] as String?;
        }
      } catch (e) {
        results.add(ToolResult.fail(call.toolName, e.toString()));
      }
    }

    final summary = _summarizeResults(intent, results, calls);
    _state = _state.copyWith(
      messages: [
        ..._state.messages,
        AgentMessage(
          role: AgentMessageRole.assistant,
          content: summary,
          toolCalls: calls,
          toolResults: results,
        ),
      ],
      status: AgentStatus.done,
    );
  }

  // ── Planning ────────────────────────────────────────────────────────────

  List<ToolCall> _planForIntent(Intent intent, String input) {
    switch (intent.id) {
      case 'create_store':
        final plan = _builder.planFromInput(input);
        return _builder.callsFor(plan);
      case 'redesign_store':
        final name = ArgumentExtractor.entityName(input);
        if (name == null) return const [];
        // For now return an empty plan; the UI will trigger the redesign
        // workflow which calls _redesigner.suggest synchronously.
        return const [];
      default:
        return intent.toolNames
            .map((t) => ToolCall(
                  toolName: t,
                  arguments: _extractArgs(t, input, intent),
                  risk: _registry.get(t)?.risk ?? ToolRisk.read,
                  humanLabel: _humanLabelFor(t, input),
                ))
            .toList();
    }
  }

  Map<String, dynamic> _extractArgs(String toolName, String input, Intent intent) {
    final args = <String, dynamic>{};
    final name = ArgumentExtractor.entityName(input);
    switch (toolName) {
      case 'read_store':
        args['query'] = name ?? input;
        break;
      case 'list_stores':
        if (input.toLowerCase().contains('inactive')) args['isActive'] = false;
        if (input.toLowerCase().contains('active')) args['isActive'] = true;
        if (input.toLowerCase().contains('suspended')) args['businessStatus'] = 'suspended';
        break;
      case 'list_orders':
        for (final s in ['placed', 'accepted', 'preparing', 'ready', 'delivered', 'cancelled']) {
          if (input.toLowerCase().contains(s)) args['status'] = s;
        }
        break;
      case 'list_drivers':
        for (final s in ['online', 'active', 'on_delivery', 'offline']) {
          if (input.toLowerCase().contains(s)) args['status'] = s;
        }
        break;
      case 'analyze_revenue':
      case 'read_revenue':
        args['window'] = input.toLowerCase().contains('month')
            ? 'month'
            : input.toLowerCase().contains('today')
                ? 'today'
                : 'week';
        break;
      case 'analyze_customer_retention':
        args['window'] = input.toLowerCase().contains('week') ? 'week' : 'month';
        break;
      case 'analyze_order_trends':
        final days = RegExp(r'(\d+)\s*day').firstMatch(input);
        if (days != null) args['days'] = int.tryParse(days.group(1)!);
        break;
      case 'create_coupon':
        args['code'] = ArgumentExtractor.couponCode(input) ?? 'WELCOME10';
        args['type'] = input.toLowerCase().contains('free delivery') ? 'free_delivery' : 'percentage';
        args['value'] = ArgumentExtractor.percentageOff(input) ?? 10;
        break;
      case 'create_campaign':
        args['name'] = name ?? 'AI Campaign';
        args['audience'] = _audienceFor(input);
        args['channel'] = _channelFor(input);
        args['message'] = ArgumentExtractor.quotedString(input) ?? 'Check out our latest offers!';
        break;
      case 'create_notification':
        args['title'] = name ?? 'Platform update';
        args['body'] = ArgumentExtractor.quotedString(input) ?? 'We have a new update for you.';
        args['audience'] = _audienceFor(input);
        break;
      case 'create_promotion':
        args['title'] = name ?? 'New promotion';
        args['type'] = ArgumentExtractor.percentageOff(input) != null ? 'percentage' : 'fixed';
        args['value'] = ArgumentExtractor.percentageOff(input) ?? 0;
        args['storeId'] = name;
        break;
      case 'generate_report':
        args['type'] = intent.id == 'analyze_revenue'
            ? 'revenue'
            : intent.id == 'analyze_drivers'
                ? 'drivers'
                : intent.id == 'analyze_store'
                    ? 'stores'
                    : 'overview';
        args['window'] = input.toLowerCase().contains('month')
            ? 'month'
            : input.toLowerCase().contains('today')
                ? 'today'
                : 'week';
        break;
    }
    return args;
  }

  String _audienceFor(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('all')) return 'all';
    if (lower.contains('driver')) return 'role:driver';
    if (lower.contains('store') || lower.contains('business')) return 'role:store';
    if (lower.contains('customer') || lower.contains('user')) return 'role:customer';
    if (lower.contains('churn') || lower.contains('win back')) return 'churned';
    if (lower.contains('new')) return 'new_users';
    return 'all';
  }

  String _channelFor(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('push')) return 'push';
    if (lower.contains('email')) return 'email';
    if (lower.contains('sms')) return 'sms';
    if (lower.contains('in-app') || lower.contains('in app')) return 'in_app';
    return 'push';
  }

  String _humanLabelFor(String tool, String input) {
    switch (tool) {
      case 'read_store':
        return 'Look up store';
      case 'list_stores':
        return 'List stores';
      case 'list_orders':
        return 'List orders';
      case 'list_drivers':
        return 'List drivers';
      case 'list_customers':
        return 'List customers';
      case 'read_revenue':
      case 'analyze_revenue':
        return 'Compute revenue';
      case 'analyze_driver_performance':
        return 'Analyze drivers';
      case 'analyze_store_performance':
        return 'Analyze stores';
      case 'analyze_customer_retention':
        return 'Analyze retention';
      case 'analyze_order_trends':
        return 'Analyze trends';
      case 'recommend_operations':
        return 'Recommend ops';
      case 'recommend_driver_allocation':
        return 'Recommend driver allocation';
      case 'recommend_marketing':
        return 'Recommend marketing';
      case 'recommend_revenue':
        return 'Recommend revenue';
      case 'create_coupon':
        return 'Create coupon';
      case 'create_campaign':
        return 'Create campaign';
      case 'create_notification':
        return 'Send notification';
      case 'create_promotion':
        return 'Create promotion';
      case 'generate_report':
        return 'Generate report';
      case 'create_store':
        return 'Create store';
      case 'create_category':
        return 'Add category';
      case 'edit_store_design':
        return 'Apply design';
      case 'edit_delivery_settings':
        return 'Configure delivery';
    }
    return tool;
  }

  String _planSummary(Intent intent, List<ToolCall> calls) {
    final lines = StringBuffer("Here's the plan — review and approve:\n");
    for (var i = 0; i < calls.length; i++) {
      final c = calls[i];
      lines.writeln('${i + 1}. ${c.humanLabel ?? c.toolName}');
    }
    return lines.toString().trim();
  }

  String _summarizeResults(Intent? intent, List<ToolResult> results, List<ToolCall> calls) {
    if (results.length == 1) {
      final r = results.first;
      if (r.success) return r.humanSummary ?? 'Done.';
      return 'Failed: ${r.error}';
    }
    final successes = results.where((r) => r.success).length;
    final fails = results.where((r) => !r.success).length;
    final lines = StringBuffer();
    if (successes > 0) lines.writeln('Completed $successes step(s).');
    if (fails > 0) lines.writeln('$fails step(s) failed.');
    for (final r in results) {
      final sym = r.success ? '✓' : '×';
      final text = r.success ? (r.humanSummary ?? '') : (r.error ?? 'failed');
      lines.writeln('$sym $text');
    }
    if (intent?.id == 'create_store') {
      lines.writeln('\nThe store is a draft. Open Stores → [name] to publish, add products, and approve.');
    }
    return lines.toString().trim();
  }

  String? _lastUserInput() {
    for (var i = _state.messages.length - 1; i >= 0; i--) {
      if (_state.messages[i].role == AgentMessageRole.user) {
        return _state.messages[i].content;
      }
    }
    return null;
  }

  /// Synchronous entry-point for the Store Redesign workflow (UI handles UX).
  Future<RedesignPlan> redesign(String storeName) {
    return _redesigner.suggest(storeName);
  }

  Future<void> applyRedesign(RedesignPlan plan) async {
    final calls = _redesigner.apply(plan);
    await _execute(calls, IntentClassifier.classify('redesign ${plan.storeName}'));
  }
}
