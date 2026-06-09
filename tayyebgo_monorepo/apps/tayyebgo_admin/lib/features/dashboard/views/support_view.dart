import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Support Tickets', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('support_tickets').orderBy('createdAt', descending: true).limit(200).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
            if (snap.hasError) return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.support_agent_rounded, size: 64, color: context.borderColor),
                    const SizedBox(height: 12),
                    Text('No tickets yet', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Customer support tickets appear here', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                  ],
                ),
              );
            }
            return _buildStats(context, docs);
          },
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<QueryDocumentSnapshot> docs) {
    int open = 0, inProgress = 0, resolved = 0;
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final s = d['status'] as String? ?? 'open';
      if (s == 'open') open++;
      else if (s == 'in_progress') inProgress++;
      else resolved++;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth < 500 ? 1 : constraints.maxWidth < 900 ? 2 : 3;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _statCard(context, Icons.circle_outlined, 'Open', '$open', context.primaryColor),
                  _statCard(context, Icons.autorenew_rounded, 'In Progress', '$inProgress', context.warningColor),
                  _statCard(context, Icons.check_circle_outline, 'Resolved', '$resolved', context.successColor),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text('All Tickets', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          ...docs.map((doc) => _ticketCard(context, doc)),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final subject = d['subject'] as String? ?? 'No subject';
    final body = d['body'] as String? ?? d['message'] as String? ?? '';
    final status = d['status'] as String? ?? 'open';
    final userName = d['userName'] as String? ?? d['email'] as String? ?? 'User';
    final createdAt = d['createdAt'];
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'open':
        statusColor = context.primaryColor;
        statusIcon = Icons.circle_outlined;
        break;
      case 'in_progress':
        statusColor = context.warningColor;
        statusIcon = Icons.autorenew_rounded;
        break;
      default:
        statusColor = context.successColor;
        statusIcon = Icons.check_circle_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(subject, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: context.textMutedColor),
              const SizedBox(width: 4),
              Text(userName, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
              const SizedBox(width: 12),
              if (createdAt is Timestamp)
                Text(_formatDate(createdAt), style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
              const Spacer(),
              if (status == 'open')
                _actionButton(context, doc.id, 'in_progress', 'In Progress', context.warningColor),
              if (status == 'in_progress')
                _actionButton(context, doc.id, 'resolved', 'Resolve', context.successColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String id, String newStatus, String label, Color color) {
    return TextButton(
      onPressed: () async {
        await FirebaseFirestore.instance.collection('support_tickets').doc(id).update({'status': newStatus});
      },
      child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
    );
  }

  String _formatDate(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
