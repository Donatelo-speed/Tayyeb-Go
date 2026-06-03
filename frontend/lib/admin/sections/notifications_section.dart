import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_design.dart';

class NotificationsSection extends StatefulWidget {
  const NotificationsSection({super.key});
  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({'title': _titleCtrl.text.trim(), 'body': _bodyCtrl.text.trim(), 'targetRole': _target, 'sentAt': FieldValue.serverTimestamp(), 'sentBy': 'admin'});
      _titleCtrl.clear(); _bodyCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent'), backgroundColor: AdminColors.success));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger)); }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targets = ['all', 'customer', 'driver', 'restaurantOwner', 'cashier'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Push Notification Center', style: isDark ? AdminTypography.h2(true) : AdminTypography.h2(false)),
        const SizedBox(height: 4),
        Text('Send targeted notifications to user groups', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false)),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)), child: Column(children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title_rounded))), const SizedBox(height: 16),
          TextField(controller: _bodyCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Message', prefixIcon: Padding(padding: EdgeInsets.only(bottom: 56), child: Icon(Icons.message_rounded)))), const SizedBox(height: 16),
          Row(children: [Text('Target:', style: isDark ? AdminTypography.label(true) : AdminTypography.label(false)), const SizedBox(width: 8), ...targets.map((t) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(t.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _target == t ? Colors.white : isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary)), selected: _target == t, onSelected: (_) => setState(() => _target = t), selectedColor: AdminColors.primary, backgroundColor: isDark ? AdminColors.bgDarkSurface : AdminColors.bgLightSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide.none)))]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _sending ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded), label: Text(_sending ? 'Sending...' : 'Send Notification'), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg))))),
        ])),
        const SizedBox(height: 32),
        Text('Previous Notifications', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('notifications').orderBy('sentAt', descending: true).limit(15).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) return Text('No notifications sent', style: isDark ? AdminTypography.caption(true) : AdminTypography.caption(false));
            return Column(children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)), child: Row(children: [
                const Icon(Icons.campaign_rounded, color: AdminColors.warning, size: 20), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['title'] as String? ?? '', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
                  if (d['body'] != null) Text(d['body'] as String, style: isDark ? AdminTypography.caption(true) : AdminTypography.caption(false), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(d['targetRole'] as String? ?? 'all', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AdminColors.primary))),
              ]));
            }).toList());
          },
        ),
      ]),
    );
  }
}