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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.partnerAccent, Color(0xFFFCD34D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.brMd,
              ),
              child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Dispatch Center',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: restaurantId == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded, size: 48, color: context.textMutedColor),
                  const SizedBox(height: 12),
                  Text(
                    'No restaurant associated',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('restaurantId', isEqualTo: restaurantId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.partnerAccent),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading orders',
                          style: GoogleFonts.inter(color: context.textMutedColor),
                        ),
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
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.partnerAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 36,
                            color: AppColors.partnerAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No orders yet',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Orders will appear here when customers place them',
                          style: GoogleFonts.inter(
                            color: context.textMutedColor,
                            fontSize: 14,
                          ),
                        ),
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
                  if (status == 'pending' || status == 'confirmed' || status == 'placed') pendingCount++;
                  if (status == 'preparing') activeCount++;
                  if (status == 'ready' || status == 'ready_for_driver') readyCount++;
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _statusCard(
                                context,
                                'Active',
                                '$activeCount',
                                Icons.kitchen_rounded,
                                AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statusCard(
                                context,
                                'Pending',
                                '$pendingCount',
                                Icons.hourglass_top_rounded,
                                context.errorColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statusCard(
                                context,
                                'Ready',
                                '$readyCount',
                                Icons.check_circle_rounded,
                                context.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text(
                          'Recent Orders',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      sliver: SliverList.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final doc = docs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] as String? ?? '';
                          final customerName = data['customerName'] as String? ?? 'Customer';
                          final items = data['items'] as List<dynamic>? ?? [];
                          final total = (data['totalAmount'] as num?)?.toDouble() ??
                              (data['total'] as num?)?.toDouble() ??
                              0;
                          final orderId = (data['orderId'] as String? ?? doc.id);
                          final shortId = orderId.length > 6 ? orderId.substring(0, 6) : orderId;

                          Color statusColor;
                          String statusLabel;
                          switch (status) {
                            case 'pending':
                            case 'placed':
                              statusColor = context.errorColor;
                              statusLabel = 'New';
                              break;
                            case 'confirmed':
                            case 'accepted':
                              statusColor = AppColors.primary;
                              statusLabel = 'Confirmed';
                              break;
                            case 'preparing':
                              statusColor = AppColors.warning;
                              statusLabel = 'Prep';
                              break;
                            case 'ready':
                            case 'ready_for_driver':
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

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: AppRadius.brLg,
                              border: Border.all(
                                color: context.borderColor.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.partnerAccent.withValues(alpha: 0.1),
                                    borderRadius: AppRadius.brMd,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#$shortId',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.partnerAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        '${items.length} item${items.length == 1 ? '' : 's'}',
                                        style: GoogleFonts.inter(
                                          color: context.textMutedColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${total.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: AppRadius.brSm,
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _statusCard(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
