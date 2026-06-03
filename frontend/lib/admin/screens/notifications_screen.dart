import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  void _sendNotification() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String targetRole = 'all';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
      backgroundColor: AdminColors.card(isDark),
      child: Container(width: 480, padding: const EdgeInsets.all(AdminSpacing.xxl), child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Send Notification', style: AdminTypography.h2(isDark)),
          const SizedBox(height: AdminSpacing.xl),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title_rounded, size: 20))),
          const SizedBox(height: AdminSpacing.md),
          TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Message', prefixIcon: Icon(Icons.message_rounded, size: 20)), maxLines: 3),
          const SizedBox(height: AdminSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: targetRole,
            decoration: const InputDecoration(labelText: 'Target', prefixIcon: Icon(Icons.group_rounded, size: 20)),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'customers', child: Text('Customers')),
              DropdownMenuItem(value: 'drivers', child: Text('Drivers')),
              DropdownMenuItem(value: 'stores', child: Text('Store Owners')),
            ],
            onChanged: (v) => setState(() => targetRole = v ?? 'all'),
          ),
          const SizedBox(height: AdminSpacing.xxl),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AdminColors.textSecondary(isDark)))),
            const SizedBox(width: AdminSpacing.md),
            ElevatedButton(onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('notifications').add({
                'title': titleCtrl.text.trim(), 'body': bodyCtrl.text.trim(),
                'targetRole': targetRole, 'sent': true,
                'sentAt': FieldValue.serverTimestamp(), 'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: const Text('Send Now')),
          ]),
        ]),
      ),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').orderBy('sentAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoadingState();
        if (snap.hasError) return AdminErrorState(message: snap.error.toString(), onRetry: () => setState(() {}));
        if (!snap.hasData) return const AdminLoadingState();

        final docs = snap.data!.docs;
        return Column(children: [
          AdminSectionHeader(
            title: 'Push Notifications', count: docs.length,
            addLabel: 'Send Notification',
            onAdd: _sendNotification,
          ),
          Expanded(
            child: docs.isEmpty
                ? const AdminEmptyState(icon: Icons.notifications_active_rounded, title: 'No notifications sent', subtitle: 'Send your first push notification', actionLabel: 'Send Notification')
                : ListView.builder(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final title = d['title'] as String? ?? '';
                      final body = d['body'] as String? ?? '';
                      final target = d['targetRole'] as String? ?? 'all';
                      final sent = d['sentAt'] as Timestamp?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        padding: const EdgeInsets.all(AdminSpacing.lg),
                        decoration: cardDecoration(isDark),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: AdminColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.md)),
                            child: const Icon(Icons.notifications_active_rounded, color: AdminColors.warning, size: 20),
                          ),
                          const SizedBox(width: AdminSpacing.lg),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(title, style: AdminTypography.h4(isDark))),
                              AdminBadge(label: target.toUpperCase(), color: AdminColors.info),
                            ]),
                            const SizedBox(height: 4),
                            Text(body, style: AdminTypography.bodySmall(isDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (sent != null) Text(timeAgo(sent.toDate()), style: AdminTypography.caption(isDark)),
                          ])),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}