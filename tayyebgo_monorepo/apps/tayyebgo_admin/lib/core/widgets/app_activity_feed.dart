import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'app_empty_state.dart';

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
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Live Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success, letterSpacing: 0.5)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
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
                              Text(d['text'] as String? ?? '', style: TextStyle(fontSize: 13, color: context.textPrimaryColor)),
                              const SizedBox(height: 2),
                              Text(_timeAgo(d['timestamp']), style: TextStyle(fontSize: 11, color: context.textMutedColor)),
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
    return AdminEmptyState(icon: Icons.bolt_rounded, title: 'No activity yet', subtitle: 'Live events will appear here as your platform runs.');
  }

  Color _activityColor(BuildContext context, String name) {
    switch (name) {
      case 'blue': return context.primaryColor;
      case 'green': return AppColors.success;
      case 'orange': return AppColors.warning;
      case 'cyan': return AppColors.cyan;
      case 'purple': return AppColors.purple;
      case 'red': return AppColors.error;
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
