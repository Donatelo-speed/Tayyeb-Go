import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/async_screen_builder.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_retry_widget.dart';
import '../theme/tayyebgo_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: userId == null
          ? const Center(child: Text('Not logged in'))
          : StreamScreenBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              onLoading: () => const ShimmerLoading(itemCount: 5),
              onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
              onSuccess: (context, snap) {
                if (snap.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: TayyebGoTheme.textMuted),
                        const SizedBox(height: 16),
                        Text('No notifications yet', style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snap.docs.length,
                    itemBuilder: (_, i) {
                      final d = snap.docs[i].data() as Map<String, dynamic>;
                      final read = d['read'] as bool? ?? false;
                      final title = d['title'] as String? ?? '';
                      final body = d['body'] as String? ?? '';
                      final time = d['createdAt'] as String? ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: TayyebGoTheme.cardDecoration,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
                          onTap: () {
                            if (!read) {
                              FirebaseFirestore.instance.collection('notifications').doc(snap.docs[i].id).update({'read': true});
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: read ? Colors.transparent : TayyebGoTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: TextStyle(fontWeight: read ? FontWeight.w400 : FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(body, style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13)),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(_timeAgo(time), style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
