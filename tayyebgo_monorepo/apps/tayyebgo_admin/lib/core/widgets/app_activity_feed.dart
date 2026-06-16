import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AppActivityFeed extends StatelessWidget {
  final int limit;
  final EdgeInsetsGeometry padding;
  const AppActivityFeed({super.key, this.limit = 10, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activity_log')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildEmpty(context);
        }
        final activities = snapshot.data!.docs;
        if (activities.isEmpty) return _buildEmpty(context);
        return TGC(
          variant: TGCVariant.outlined,
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.bolt_rounded, size: 18, color: context.primaryColor),
                const SizedBox(width: 6),
                Text('Live Activity', style: AppTypography.bodyBold.copyWith(color: context.textPrimaryColor)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.successColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brChip,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    TGDot(color: context.successColor, size: 6),
                    const SizedBox(width: 4),
                    Text('LIVE', style: AppTypography.labelSmall.copyWith(color: context.successColor)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => Divider(height: 16, color: context.borderColor),
                  itemBuilder: (_, i) {
                    final d = activities[i].data() as Map<String, dynamic>;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(color: _activityColor(context, d['color'] as String? ?? 'grey'), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['text'] as String? ?? '', style: AppTypography.body.copyWith(color: context.textPrimaryColor)),
                              const SizedBox(height: 2),
                              Text(_timeAgo(d['timestamp']), style: AppTypography.bodySmall.copyWith(color: context.textMutedColor)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return TGEmptyState(
      icon: Icons.bolt_rounded,
      title: 'No activity yet',
      description: 'Live events will appear here as your platform runs.',
    );
  }

  Color _activityColor(BuildContext context, String name) {
    switch (name) {
      case 'blue': return context.primaryColor;
      case 'green': return context.successColor;
      case 'orange': return context.warningColor;
      case 'cyan': return const Color(0xFF06B6D4);
      case 'purple': return const Color(0xFF8B5CF6);
      case 'red': return context.errorColor;
      default: return context.textMutedColor;
    }
  }

  String _timeAgo(Object? ts) {
    if (ts is! Timestamp) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
