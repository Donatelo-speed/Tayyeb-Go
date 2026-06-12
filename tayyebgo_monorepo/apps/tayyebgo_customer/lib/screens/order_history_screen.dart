import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_core/ui/error_state.dart';
import 'package:tayyebgo_core/ui/skeleton_loader.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final customerId = auth.user?.id;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Order History', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.textMutedColor,
          indicatorColor: context.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: customerId == null
          ? Center(child: Text('Not logged in', style: GoogleFonts.inter(color: context.textMutedColor)))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<CustomerHomeProvider>().watchOrderHistory(customerId),
              builder: (context, snap) {
                if (snap.hasError) {
                  debugPrint('Order history error: ${snap.error}');
                  return ErrorState(
                    icon: Icons.error_outline_rounded,
                    title: 'Failed to load orders',
                    subtitle: 'Please check your connection and try again',
                    actionText: 'Retry',
                    onAction: () => setState(() {}),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return SkeletonList(itemCount: 5, itemHeight: 80);
                }
                final docs = snap.data ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Icon(Icons.receipt_long_outlined, size: 36, color: context.textMutedColor),
                        ),
                        const SizedBox(height: 16),
                        Text('No past orders', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Your orders will appear here', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                      ],
                    ),
                  );
                }

                final activeOrders = docs.where((d) => !['delivered', 'cancelled'].contains(d['status'])).toList();
                final completedOrders = docs.where((d) => d['status'] == 'delivered').toList();
                final cancelledOrders = docs.where((d) => d['status'] == 'cancelled').toList();

                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildOrderList(context, activeOrders, 'No active orders', 'Your current orders will appear here'),
                    _buildOrderList(context, completedOrders, 'No completed orders', 'Delivered orders will appear here'),
                    _buildOrderList(context, cancelledOrders, 'No cancelled orders', 'Cancelled orders will appear here'),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Map<String, dynamic>> orders, String emptyTitle, String emptyDesc) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: emptyTitle,
        subtitle: emptyDesc,
      );
    }

    return RefreshIndicator(
      color: context.primaryColor,
      backgroundColor: context.surfaceColor,
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? '';
    final isDelivered = status == 'delivered';
    final isCancelled = status == 'cancelled';
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final restaurantName = order['restaurantName'] as String? ?? 'Order';
    final itemCount = (order['items'] as List?)?.length ?? 0;

    final statusColor = isDelivered
        ? context.successColor
        : isCancelled
            ? context.errorColor
            : context.primaryColor;
    final statusText = isDelivered
        ? 'Delivered'
        : isCancelled
            ? 'Cancelled'
            : status.isEmpty
                ? ''
                : status[0].toUpperCase() + status.substring(1);

    return GestureDetector(
      onTap: () => context.push('/tracking/${order['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDelivered
                    ? Icons.check_circle_rounded
                    : isCancelled
                        ? Icons.cancel_rounded
                        : Icons.receipt_long_rounded,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusText, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                      if (itemCount > 0) ...[
                        const SizedBox(width: 8),
                        Text('$itemCount items', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor),
                ),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
