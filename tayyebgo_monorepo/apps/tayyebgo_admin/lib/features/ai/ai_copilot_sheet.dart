import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tayyebgo_admin/core/ai/agent_types.dart';
import 'package:tayyebgo_admin/core/ai/ai_copilot.dart';
import 'package:tayyebgo_admin/core/ai/store_redesigner.dart';
import 'package:tayyebgo_admin/core/design_system/design_system.dart';
import 'package:tayyebgo_admin/core/widgets/responsive_builder.dart';
import 'package:tayyebgo_core/presentation/theme/app_colors.dart';
import 'package:tayyebgo_core/presentation/theme/theme_provider.dart';

class AiCopilotSheet extends StatefulWidget {
  const AiCopilotSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiCopilotSheet(),
    );
  }

  @override
  State<AiCopilotSheet> createState() => _AiCopilotSheetState();
}

class _AiCopilotSheetState extends State<AiCopilotSheet> {
  final _copilot = AiCopilot();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _busy = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit([String? override]) async {
    final text = (override ?? _inputController.text).trim();
    if (text.isEmpty || _busy) return;
    _inputController.clear();
    setState(() => _busy = true);
    await _copilot.submit(text);
    if (!mounted) return;
    setState(() => _busy = false);
    _scrollToEnd();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    await _copilot.confirmPlan();
    if (!mounted) return;
    setState(() => _busy = false);
    _scrollToEnd();
  }

  Future<void> _reject() async {
    _copilot.rejectPlan();
    if (!mounted) return;
    setState(() {});
    _scrollToEnd();
  }

  Future<void> _startRedesign() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NamePromptDialog(
        title: 'Redesign store',
        label: 'Store name',
        hint: 'e.g. Al Shifa Pharmacy',
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final plan = await _copilot.redesign(name.trim());
      if (!mounted) return;
      final apply = await showDialog<bool>(
        context: context,
        builder: (_) => _RedesignPreviewDialog(plan: plan),
      );
      if (apply == true) {
        await _copilot.applyRedesign(plan);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final state = _copilot.state;
    final isDark = context.isDark;
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ResponsiveBuilder(
        builder: (ctx, layout) {
          final isMobile = layout.isMobile;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 720,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: isMobile ? 0.9 : 0.85,
                minChildSize: isMobile ? 0.4 : 0.5,
                maxChildSize: isMobile ? 0.95 : 0.92,
                expand: false,
                builder: (ctx, scroll) => Container(
                  decoration: BoxDecoration(
                    color: isDark ? DarkAppColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isMobile ? 24 : 32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? DarkAppColors.border : AppColors.border,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SheetHeader(
                        status: state.status,
                        busy: _busy,
                        onClose: () => Navigator.of(context).pop(),
                        onReset: () {
                          _copilot.reset();
                          setState(() {});
                        },
                      ),
                      if (state.pendingPlan.isNotEmpty)
                        _PlanBar(
                          plan: state.pendingPlan,
                          busy: _busy,
                          onConfirm: _confirm,
                          onReject: _reject,
                        ),
                      Expanded(
                        child: RepaintBoundary(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            itemCount: state.messages.length,
                            itemBuilder: (ctx, i) => _MessageBubble(message: state.messages[i]),
                          ),
                        ),
                      ),
                      _QuickActions(onTap: (s) => _submit(s), onRedesign: _startRedesign, busy: _busy),
                      _InputBar(controller: _inputController, onSubmit: () => _submit(), busy: _busy),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final AgentStatus status;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onReset;
  const _SheetHeader({
    required this.status,
    required this.busy,
    required this.onClose,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isActive = busy || status == AgentStatus.executing || status == AgentStatus.planning;
    final statusColor = isActive ? context.warningColor : context.successColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? DarkAppColors.divider : AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Copilot',
                    style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Thinking…' : 'Online',
                      style: AppTypography.label.copyWith(color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Reset Copilot conversation',
            button: true,
            child: IconButton(
              tooltip: 'Reset conversation',
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
            ),
          ),
          Semantics(
            label: 'Close Copilot',
            button: true,
            child: IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AgentMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.role == AgentMessageRole.system) return const SizedBox.shrink();
    final isUser = message.role == AgentMessageRole.user;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final isDark = context.isDark;
    final bubbleColor = isUser
        ? context.primaryColor
        : (isDark ? DarkAppColors.surfaceAlt : AppColors.surfaceAlt);
    final textColor = isUser ? Colors.white : context.textPrimaryColor;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.lg),
      topRight: const Radius.circular(AppRadius.lg),
      bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
      bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
    );
    final calls = message.toolCalls;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
            if (calls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: isUser ? WrapAlignment.end : WrapAlignment.start,
                children: [for (final c in calls) _ToolCallChip(call: c)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolCallChip extends StatelessWidget {
  final ToolCall call;
  const _ToolCallChip({required this.call});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final risk = call.risk;
    final riskColor = switch (risk) {
      ToolRisk.read => context.successColor,
      ToolRisk.write => context.warningColor,
      ToolRisk.destructive => context.errorColor,
    };
    final riskLabel = switch (risk) {
      ToolRisk.read => 'READ',
      ToolRisk.write => 'WRITE',
      ToolRisk.destructive => 'DESTRUCTIVE',
    };
    final icon = switch (risk) {
      ToolRisk.read => Icons.visibility_outlined,
      ToolRisk.write => Icons.edit_outlined,
      ToolRisk.destructive => Icons.warning_amber,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.surface : AppColors.surface,
        border: Border.all(color: isDark ? DarkAppColors.divider : AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: riskColor),
          const SizedBox(width: 6),
          Text(call.humanLabel ?? call.toolName,
              style: AppTypography.label.copyWith(color: context.textPrimaryColor)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(riskLabel,
                style: AppTypography.label.copyWith(color: riskColor, fontSize: 9)),
          ),
        ],
      ),
    );
  }
}

class _PlanBar extends StatelessWidget {
  final List<ToolCall> plan;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  const _PlanBar({
    required this.plan,
    required this.busy,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = context.primaryColor;
    return Semantics(
      liveRegion: true,
      label: 'Plan ready with ${plan.length} step(s). Review and approve.',
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: isDark ? DarkAppColors.divider : AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: primary, size: 18),
              const SizedBox(width: 6),
              Text('Plan ready — ${plan.length} step(s)',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < plan.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 10,
                      backgroundColor: primary,
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(plan[i].humanLabel ?? plan[i].toolName,
                          style: AppTypography.caption
                              .copyWith(color: context.textPrimaryColor))),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: busy ? null : onConfirm,
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Approve & run'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ValueChanged<String> onTap;
  final VoidCallback onRedesign;
  final bool busy;
  const _QuickActions({required this.onTap, required this.onRedesign, required this.busy});

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, String?)>[
      ('Create store', Icons.add_business_outlined, 'create a pharmacy called Al Shifa'),
      ('Analyze revenue', Icons.trending_up, 'analyze revenue this week'),
      ('Find issues', Icons.search, 'find inactive drivers'),
      ('Run report', Icons.summarize_outlined, 'generate a revenue report for this month'),
      ('Redesign', Icons.brush_outlined, null),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final a = actions[i];
          return Semantics(
            button: true,
            label: 'Quick action: ${a.$1}',
            child: ActionChip(
              avatar: Icon(a.$2, size: 16, color: context.primaryColor),
              label: Text(a.$1, style: AppTypography.label.copyWith(color: context.textPrimaryColor)),
              onPressed: busy
                  ? null
                  : () {
                      if (a.$3 != null) onTap(a.$3!);
                      else onRedesign();
                    },
            ),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool busy;
  const _InputBar({required this.controller, required this.onSubmit, required this.busy});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? DarkAppColors.divider : AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: 'Ask Copilot — try "create a pharmacy called Al Shifa"',
                  filled: true,
                  fillColor: isDark ? DarkAppColors.surfaceAlt : AppColors.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Send message to Copilot',
              button: true,
              child: FilledButton(
                onPressed: busy ? null : onSubmit,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamePromptDialog extends StatefulWidget {
  final String title;
  final String label;
  final String hint;
  const _NamePromptDialog({required this.title, required this.label, required this.hint});
  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
            child: const Text('Next')),
      ],
    );
  }
}

class _RedesignPreviewDialog extends StatelessWidget {
  final RedesignPlan plan;
  const _RedesignPreviewDialog({required this.plan});

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Redesign "${plan.storeName}"',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('AI suggestion',
                  style: AppTypography.label.copyWith(color: context.textSecondaryColor)),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PreviewBox(plan: plan, color: primary),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(label: 'Template', from: plan.fromTemplate, to: plan.toTemplate),
                      if (plan.primaryColor != null)
                        _InfoRow(label: 'Primary', from: '—', to: plan.primaryColor!),
                      if (plan.accentColor != null)
                        _InfoRow(label: 'Accent', from: '—', to: plan.accentColor!),
                      if (plan.banner != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text('Banner', style: AppTypography.label.copyWith(color: context.textSecondaryColor)),
                        const SizedBox(height: 4),
                        Text(plan.banner!,
                            style: AppTypography.caption.copyWith(color: context.textPrimaryColor)),
                      ],
                      if (plan.newSections.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text('Sections', style: AppTypography.label.copyWith(color: context.textSecondaryColor)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: plan.newSections
                              .map((s) => Chip(
                                  label: Text(s,
                                      style: AppTypography.label.copyWith(
                                          color: context.textPrimaryColor))))
                              .toList(),
                        ),
                      ],
                      if (plan.improvements.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Why', style: AppTypography.label.copyWith(color: context.textSecondaryColor)),
                        const SizedBox(height: 4),
                        for (final imp in plan.improvements)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6, right: 6),
                                  child: Icon(Icons.fiber_manual_record, size: 6),
                                ),
                                Expanded(
                                    child: Text(imp,
                                        style: AppTypography.caption
                                            .copyWith(color: context.textPrimaryColor))),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Apply redesign'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final RedesignPlan plan;
  final Color color;
  const _PreviewBox({required this.plan, required this.color});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.6)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 12,
              child: Text(plan.storeName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white)),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Text(plan.banner ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.95))),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(plan.toTemplate,
                    style: AppTypography.label.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String from;
  final String to;
  const _InfoRow({required this.label, required this.from, required this.to});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTypography.label.copyWith(color: context.textSecondaryColor)),
          ),
          Expanded(
            child: Row(
              children: [
                Text(from, style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 12),
                const SizedBox(width: 6),
                Text(to,
                    style: AppTypography.bodyBold.copyWith(color: context.textPrimaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
