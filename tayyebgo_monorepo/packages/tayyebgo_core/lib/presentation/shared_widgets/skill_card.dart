import 'package:flutter/material.dart';
import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_execution.dart';
import '../../domain/enums/skill_execution_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final SkillExecution? lastExecution;
  final bool compact;
  final VoidCallback? onTap;

  const SkillCard({
    super.key,
    required this.skill,
    this.lastExecution,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: skill.destructive
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _StatusIndicator(lastExecution: lastExecution),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    skill.name,
                    style: compact
                        ? AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          )
                        : AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (skill.destructive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'DESTRUCTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                skill.description,
                style: AppTypography.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${skill.inputSchema.required.length} required params',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final SkillExecution? lastExecution;

  const _StatusIndicator({this.lastExecution});

  @override
  Widget build(BuildContext context) {
    final status = lastExecution?.status;
    final color = switch (status) {
      SkillExecutionStatus.running => AppColors.accent,
      SkillExecutionStatus.success => AppColors.success,
      SkillExecutionStatus.failed => AppColors.error,
      _ => AppColors.textMuted,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: status == SkillExecutionStatus.running
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}
