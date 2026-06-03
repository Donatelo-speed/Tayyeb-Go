import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _statusFilter = 'all';

  Future<void> _updateStatus(String id, String status) async {
    try { await FirebaseFirestore.instance.collection('support_tickets').doc(id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()}); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const statuses = ['all', 'open', 'assigned', 'in_progress', 'resolved', 'closed'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('support_tickets').orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoadingState();
        if (snap.hasError) return AdminErrorState(message: snap.error.toString(), onRetry: () => setState(() {}));
        if (!snap.hasData) return const AdminLoadingState();

        var docs = snap.data!.docs;
        if (_statusFilter != 'all') {
          docs = docs.where((d) => (d.data() as Map)['status'] == _statusFilter).toList();
        }

        return Column(children: [
          AdminSectionHeader(
            title: 'Support Center', count: docs.length,
            filterChips: statuses.map((s) => Padding(
              padding: const EdgeInsets.only(right: AdminSpacing.sm),
              child: FilterChip(
                label: Text(s == 'all' ? 'All' : s.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)),
                selected: _statusFilter == s,
                onSelected: (v) => setState(() => _statusFilter = v ? s : 'all'),
                selectedColor: AdminColors.statusColor(s).withValues(alpha: 0.15),
              ),
            )).toList(),
          ),
          Expanded(
            child: docs.isEmpty
                ? const AdminEmptyState(icon: Icons.headset_mic_rounded, title: 'No support tickets', subtitle: 'Tickets from users will appear here')
                : ListView.builder(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final subject = d['subject'] as String? ?? '';
                      final description = d['description'] as String? ?? '';
                      final type = d['type'] as String? ?? 'complaint';
                      final status = d['status'] as String? ?? 'open';
                      final priority = d['priority'] as String? ?? 'medium';
                      final userName = d['userName'] as String? ?? 'Unknown';
                      final created = (d['createdAt'] as Timestamp?)?.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        padding: const EdgeInsets.all(AdminSpacing.lg),
                        decoration: cardDecoration(isDark),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AdminColors.statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)),
                            child: Icon(_ticketIcon(type), color: AdminColors.statusColor(status), size: 20),
                          ),
                          const SizedBox(width: AdminSpacing.lg),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(subject, style: AdminTypography.h4(isDark)),
                              const SizedBox(width: AdminSpacing.sm),
                              AdminStatusBadge(status: status),
                              const SizedBox(width: AdminSpacing.xs),
                              AdminBadge(label: priority.toUpperCase(), color: priority == 'high' ? AdminColors.danger : priority == 'medium' ? AdminColors.warning : AdminColors.info),
                            ]),
                            const SizedBox(height: 4),
                            Text('$userName  ·  $type  ·  ${description.length > 80 ? '${description.substring(0, 80)}...' : description}', style: AdminTypography.bodySmall(isDark)),
                            if (created != null) Text(timeAgo(created), style: AdminTypography.caption(isDark)),
                          ])),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18),
                            onSelected: (v) => _updateStatus(docs[i].id, v),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'open', child: Text('Open')),
                              const PopupMenuItem(value: 'assigned', child: Text('Assign')),
                              const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                              const PopupMenuItem(value: 'resolved', child: Text('Resolve')),
                              const PopupMenuItem(value: 'closed', child: Text('Close')),
                            ],
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }

  IconData _ticketIcon(String type) {
    switch (type) {
      case 'complaint': return Icons.report_problem_rounded;
      case 'suggestion': return Icons.lightbulb_rounded;
      case 'refund': return Icons.replay_rounded;
      case 'bug': return Icons.bug_report_rounded;
      default: return Icons.help_outline_rounded;
    }
  }
}