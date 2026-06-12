import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerDispatchCenterScreen extends StatelessWidget {
  const PartnerDispatchCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final restaurantId = user.vendorId;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Dispatch Center', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: restaurantId == null
          ? Center(child: Text('No restaurant associated with this account.'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('restaurantId', isEqualTo: restaurantId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.primaryColor));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                  const SizedBox(height: 12),
                  Text('Error loading orders', style: GoogleFonts.inter(color: context.textMutedColor)),
                ],
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 64, color: context.textMutedColor),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor)),
                  const SizedBox(height: 4),
                  Text('Orders will appear here when customers place them', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                ],
              ),
            );
          }

          int activeCount = 0;
          int pendingCount = 0;
          int readyCount = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            if (status == 'pending' || status == 'confirmed') pendingCount++;
            if (status == 'preparing') activeCount++;
            if (status == 'ready') readyCount++;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _statusCard(context, 'Active', '$activeCount', Icons.kitchen_rounded, context.warningColor)),
                  const SizedBox(width: 8),
                  Expanded(child: _statusCard(context, 'Pending', '$pendingCount', Icons.hourglass_top_rounded, context.errorColor)),
                  const SizedBox(width: 8),
                  Expanded(child: _statusCard(context, 'Ready', '$readyCount', Icons.check_circle_rounded, context.successColor)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Recent Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
              const SizedBox(height: 12),
              ...docs.take(20).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? '';
                final customerName = data['customerName'] as String? ?? 'Customer';
                final items = data['items'] as List<dynamic>? ?? [];
                final total = (data['total'] as num?)?.toDouble() ?? 0;
                final orderId = (data['orderId'] as String? ?? doc.id);
                final shortId = orderId.length > 6 ? orderId.substring(0, 6) : orderId;

                Color statusColor;
                String statusLabel;
                switch (status) {
                  case 'pending':
                    statusColor = context.errorColor;
                    statusLabel = 'New';
                    break;
                  case 'confirmed':
                    statusColor = context.primaryColor;
                    statusLabel = 'Confirmed';
                    break;
                  case 'preparing':
                    statusColor = context.warningColor;
                    statusLabel = 'Prep';
                    break;
                  case 'ready':
                    statusColor = context.successColor;
                    statusLabel = 'Ready';
                    break;
                  case 'delivered':
                  case 'completed':
                    statusColor = context.textMutedColor;
                    statusLabel = 'Done';
                    break;
                  default:
                    statusColor = context.textMutedColor;
                    statusLabel = status;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _orderCard(
                    context,
                    '#$shortId',
                    customerName,
                    '${items.length} item${items.length == 1 ? '' : 's'}',
                    'SYP ${total.toStringAsFixed(0)}',
                    statusLabel,
                    statusColor,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(BuildContext context, String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(count, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, color: context.textMutedColor)),
        ],
      ),
    );
  }

  Widget _orderCard(BuildContext context, String id, String customer, String items, String total, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(id, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
              const SizedBox(height: 2),
              Text('$customer · $items', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(total, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
