import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';



class SupportView extends StatefulWidget {
  const SupportView();
  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      showAppBar: false,
      title: 'Support Center',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              _filterChip('All', 'all'),
              const SizedBox(width: 4),
              _filterChip('Open', 'open'),
              const SizedBox(width: 4),
              _filterChip('Pending', 'pending'),
              const SizedBox(width: 4),
              _filterChip('Resolved', 'resolved'),
              const Spacer(),
              Text('${_statusFilter == 'all' ? '' : _statusFilter} Tickets', style: AppTypography.bodyBold),
            ]),
          ),
          Expanded(
            child: StreamScreenBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('support_tickets').orderBy('createdAt', descending: true).limit(100).snapshots(),
              onLoading: () => const ShimmerLoading(itemCount: 5),
              onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
              onSuccess: (context, snap) {
                var docs = snap.docs.toList();
                if (_statusFilter != 'all') {
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return (d['status'] as String? ?? 'open') == _statusFilter;
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.support_agent_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('No support tickets', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final userName = d['userName'] as String? ?? 'Unknown';
                    final userRole = d['userRole'] as String? ?? 'customer';
                    final subject = d['subject'] as String? ?? 'No subject';
                    final message = d['message'] as String? ?? '';
                    final status = d['status'] as String? ?? 'open';
                    final priority = d['priority'] as String? ?? 'normal';
                    final createdAt = d['createdAt'] as Timestamp?;
                    final category = d['category'] as String? ?? 'general';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: TayyebGoTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _roleColor(userRole).withValues(alpha: 0.1),
                              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: TextStyle(color: _roleColor(userRole), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(subject, style: AppTypography.bodyBold),
                                Row(children: [
                                  Text(userName, style: AppTypography.small),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.textMuted.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(userRole[0].toUpperCase() + userRole.substring(1), style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ),
                                  const SizedBox(width: 4),
                                  _priorityBadge(priority),
                                ]),
                              ]),
                            ),
                            _statusBadge(status),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'open') _updateTicketStatus(context, docs[i].id, 'open');
                                if (v == 'pending') _updateTicketStatus(context, docs[i].id, 'pending');
                                if (v == 'resolved') _updateTicketStatus(context, docs[i].id, 'resolved');
                                if (v == 'reply') _showReplyDialog(context, docs[i].id, userName, subject);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'open', child: ListTile(leading: Icon(Icons.check_circle, size: 20, color: Colors.blue), title: Text('Mark Open'))),
                                const PopupMenuItem(value: 'pending', child: ListTile(leading: Icon(Icons.schedule, size: 20, color: Colors.orange), title: Text('Mark Pending'))),
                                const PopupMenuItem(value: 'resolved', child: ListTile(leading: Icon(Icons.check_circle, size: 20, color: AppColors.success), title: Text('Mark Resolved'))),
                                const PopupMenuItem(value: 'reply', child: ListTile(leading: Icon(Icons.reply, size: 20), title: Text('Reply'))),
                              ],
                            ),
                          ]),
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(message, style: AppTypography.body),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.category, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(category[0].toUpperCase() + category.substring(1), style: AppTypography.small),
                            const Spacer(),
                            if (createdAt != null) ...[
                              Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(_formatDate(createdAt.toDate()), style: AppTypography.small),
                            ],
                          ]),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'driver': return Colors.cyan;
      case 'customer': return Colors.blue;
      case 'restaurantOwner': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _priorityBadge(String priority) {
    Color c;
    switch (priority) {
      case 'high': c = Colors.red; break;
      case 'normal': c = Colors.blue; break;
      case 'low': c = AppColors.textMuted; break;
      default: c = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(priority[0].toUpperCase() + priority.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Widget _statusBadge(String status) {
    Color c;
    switch (status) {
      case 'open': c = Colors.blue; break;
      case 'pending': c = Colors.orange; break;
      case 'resolved': c = AppColors.success; break;
      default: c = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Future<void> _updateTicketStatus(BuildContext context, String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('support_tickets').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) context.showSuccess('Ticket marked as $status');
    } catch (e) {
      if (context.mounted) context.showError('Failed to update ticket status');
    }
  }

  void _showReplyDialog(BuildContext context, String ticketId, String userName, String subject) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reply to $userName'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Re: $subject', style: AppTypography.caption),
            const SizedBox(height: 12),
            TextField(controller: ctrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Reply', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).update({
                    'status': 'pending',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) ctx.showSuccess('Reply sent');
                  Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ctx.showError('Failed to send reply');
                }
              }
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}
