import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_execution.dart';
import '../../domain/enums/skill_execution_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';
import 'destructive_action_overlay.dart';
import 'skill_card.dart';

class SkillExecutionView extends StatefulWidget {
  final Skill skill;
  final SkillExecution? execution;
  final bool showHistory;
  final List<SkillExecution>? history;
  final Future<SkillExecution> Function(Map<String, dynamic> input)? onExecute;
  final VoidCallback? onDismiss;

  const SkillExecutionView({
    super.key,
    required this.skill,
    this.execution,
    this.showHistory = false,
    this.history,
    this.onExecute,
    this.onDismiss,
  });

  @override
  State<SkillExecutionView> createState() => _SkillExecutionViewState();
}

class _SkillExecutionViewState extends State<SkillExecutionView>
    with SingleTickerProviderStateMixin {
  final _inputController = <String, TextEditingController>{};
  bool _isExecuting = false;
  SkillExecution? _execution;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _execution = widget.execution;
    _initInputs();
    if (widget.skill.inputSchema.properties != null) {
      for (final entry in widget.skill.inputSchema.properties!.entries) {
        _inputController[entry.key] = TextEditingController();
      }
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  void _initInputs() {
    if (widget.execution != null) {
      for (final entry in widget.execution!.payload.entries) {
        _inputController[entry.key] =
            TextEditingController(text: entry.value.toString());
      }
    }
  }

  @override
  void didUpdateWidget(SkillExecutionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.execution != _execution) {
      setState(() {
        _execution = widget.execution;
      });
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    for (final c in _inputController.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildInput() {
    final input = <String, dynamic>{};
    for (final entry in _inputController.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        final propSchema =
            widget.skill.inputSchema.properties?[entry.key] as Map<String, dynamic>?;
        final type = propSchema?['type'] as String?;
        input[entry.key] = _coerceValue(text, type);
      }
    }
    return input;
  }

  dynamic _coerceValue(String text, String? type) {
    switch (type) {
      case 'number':
        return double.tryParse(text) ?? text;
      case 'integer':
        return int.tryParse(text) ?? text;
      case 'boolean':
        if (text.toLowerCase() == 'true') return true;
        if (text.toLowerCase() == 'false') return false;
        return text;
      default:
        return text;
    }
  }

  Future<void> _execute() async {
    if (_isExecuting || widget.onExecute == null) return;

    final input = _buildInput();

    if (widget.skill.destructive) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DestructiveActionOverlay(
          skillName: widget.skill.name,
          description: widget.skill.description,
          input: input,
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isExecuting = true);
    try {
      final result = await widget.onExecute!(input);
      if (mounted) {
        setState(() {
          _execution = result;
          _isExecuting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExecuting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _execution?.status == SkillExecutionStatus.running ||
        _isExecuting;
    final hasFailed = _execution?.status == SkillExecutionStatus.failed;
    final hasSucceeded = _execution?.status == SkillExecutionStatus.success;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isRunning, hasFailed, hasSucceeded),
          if (hasFailed) _buildErrorBanner(),
          _buildInputSection(),
          _buildActionBar(isRunning),
          if (_execution != null && _execution!.status.isTerminal)
            _buildCollapsibleLogs(),
          if (widget.showHistory && widget.history != null)
            _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isRunning, bool hasFailed, bool hasSucceeded) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (isRunning)
            _buildRunningIndicator()
          else if (hasSucceeded)
            _buildStatusIcon(AppColors.success, Icons.check_circle)
          else if (hasFailed)
            _buildStatusIcon(AppColors.error, Icons.error_outline)
          else
            _buildStatusIcon(AppColors.textMuted, Icons.radio_button_unchecked),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.skill.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.skill.description,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_execution?.duration != null)
            Text(
              _formatDuration(_execution!.duration!),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRunningIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation!,
      builder: (ctx, child) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withValues(alpha: _pulseAnimation!.value),
        ),
        child: const Center(
          child: SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(Color color, IconData icon) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.error.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: AppColors.error),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              _execution?.error ?? 'Execution failed',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    final properties = widget.skill.inputSchema.properties;
    if (properties == null || properties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Text(
            'No parameters required',
            style: AppTypography.caption,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parameters',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...properties.entries.map((entry) {
            final key = entry.key;
            final propSchema = entry.value as Map<String, dynamic>;
            final isRequired =
                widget.skill.inputSchema.required.contains(key);
            final type = propSchema['type'] as String? ?? 'string';
            final desc = propSchema['description'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TextField(
                controller: _inputController[key],
                enabled: !_isExecuting,
                decoration: InputDecoration(
                  labelText: key,
                  hintText: desc,
                  helperText: type,
                  isDense: true,
                  labelStyle: AppTypography.caption,
                  helperStyle: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(
                        color: isRequired
                            ? AppColors.primary
                            : AppColors.textMuted),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: isRequired
                      ? const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(
                            '*',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : null,
                ),
                style: AppTypography.body.copyWith(fontSize: 13),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isRunning) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (widget.onDismiss != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Close'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          const Spacer(),
          if (_execution?.status == SkillExecutionStatus.success &&
              _execution?.output != null)
            TextButton.icon(
              onPressed: () => _copyOutput(_execution!.output!),
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Copy Output'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          if (widget.onExecute != null)
            FilledButton.icon(
              onPressed: isRunning ? null : _execute,
              icon: isRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      widget.skill.destructive
                          ? Icons.warning_amber_rounded
                          : Icons.play_arrow,
                      size: 16,
                    ),
              label: Text(
                isRunning
                    ? 'Running...'
                    : widget.skill.destructive
                        ? 'Execute (Destructive)'
                        : 'Execute',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: widget.skill.destructive
                    ? AppColors.error
                    : AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleLogs() {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        title: Text(
          'Execution Details',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        leading: Icon(
          Icons.code,
          size: 16,
          color: AppColors.textSecondary,
        ),
        children: [
          _buildLogBlock(
            'Input Payload',
            const JsonEncoder.withIndent('  ')
                .convert(_execution!.payload),
          ),
          if (_execution!.output != null)
            _buildLogBlock(
              'Output',
              const JsonEncoder.withIndent('  ')
                  .convert(_execution!.output),
            ),
          if (_execution!.error != null)
            _buildLogBlock('Error', _execution!.error!),
        ],
      ),
    );
  }

  Widget _buildLogBlock(String label, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final history = widget.history!;
    if (history.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        title: Text(
          'Usage History (${history.length})',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        leading: Icon(
          Icons.history,
          size: 16,
          color: AppColors.textSecondary,
        ),
        children: history.reversed.take(10).map((exec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SkillCard(
              skill: widget.skill,
              lastExecution: exec,
              compact: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMilliseconds < 1000) return '${d.inMilliseconds}ms';
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  void _copyOutput(Map<String, dynamic> output) {
    final json = const JsonEncoder.withIndent('  ').convert(output);
    // In a real app this would use Clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Output copied (${json.length} chars)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
