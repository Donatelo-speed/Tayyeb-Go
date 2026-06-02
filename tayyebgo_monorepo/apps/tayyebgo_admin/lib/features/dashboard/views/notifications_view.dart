import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'all_users';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      title: 'Notification Center',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final compose = _buildComposer(context);
          final history = _buildHistory(context);
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 380, child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20), child: compose))),
                const VerticalDivider(width: 1),
                Expanded(child: history),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [compose, const SizedBox(height: 24), SizedBox(height: 500, child: history)],
          );
        },
      ),
    ));
  }

  Widget _buildComposer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Compose Campaign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Send a push to users, drivers, or stores.', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _audience,
            decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'all_users', child: Text('All Users')),
              DropdownMenuItem(value: 'all_drivers', child: Text('All Drivers')),
              DropdownMenuItem(value: 'all_owners', child: Text('All Store Owners')),
              DropdownMenuItem(value: 'zone_customers', child: Text('Customers in Zone')),
              DropdownMenuItem(value: 'new_users', child: Text('New Users (7d)')),
            ],
            onChanged: (v) => setState(() => _audience = v ?? 'all_users'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), hintText: 'Free delivery today'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder(), hintText: 'Order from any store and get free delivery.'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _titleCtrl.text = 'New restaurant added';
                    _bodyCtrl.text = 'Check out the latest addition to TayyebGo!';
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Template'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, size: 16),
                  label: Text(_sending ? 'Sending...' : 'Send'),
                  style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 6, itemHeight: 70);
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off, size: 56, color: context.textMutedColor.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('No notifications sent yet', style: TextStyle(color: context.textMutedColor, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final title = d['title'] as String? ?? 'Untitled';
            final body = d['body'] as String? ?? '';
            final audience = d['audience'] as String? ?? 'unknown';
            final ts = d['createdAt'];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: cardDecoBordered(context),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_iconForAudience(audience), size: 18, color: context.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(body, style: TextStyle(fontSize: 12, color: context.textSecondaryColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 2),
                        Text(_formatTimestamp(ts), style: TextStyle(fontSize: 10, color: context.textMutedColor)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: context.dividerColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                    child: Text(audience.replaceAll('_', ' '), style: TextStyle(fontSize: 10, color: context.textSecondaryColor)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconForAudience(String audience) {
    switch (audience) {
      case 'all_drivers': return Icons.delivery_dining;
      case 'all_owners': return Icons.store;
      case 'zone_customers': return Icons.location_on;
      case 'new_users': return Icons.person_add;
      default: return Icons.people;
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '—';
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body are required'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'audience': _audience,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
        'status': 'sent',
      });
      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification queued'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
