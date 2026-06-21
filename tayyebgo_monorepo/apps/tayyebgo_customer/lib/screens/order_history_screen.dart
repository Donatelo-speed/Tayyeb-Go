import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_core/ui/skeleton_loader.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Order History',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    color: context.textPrimaryColor,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            AnimatedFadeSlide(
              delay: 100,
              duration: const Duration(milliseconds: 500),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: Colors.white,
                  unselectedLabelColor: context.textMutedColor,
                  indicatorColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  dividerColor: Colors.transparent,
                  splashBorderRadius: AppRadius.brMd,
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: customerId == null
                  ? Center(
                      child: Text(
                        'Not logged in',
                        style: GoogleFonts.inter(color: context.textMutedColor),
                      ),
                    )
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: context.read<CustomerHomeProvider>().watchOrderHistory(customerId),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Failed to load orders',
                            subtitle: 'Please check your connection and try again',
                            actionText: 'Retry',
                            onAction: () => setState(() {}),
                            accentColor: context.errorColor,
                          );
                        }
                        if (snap.connectionState == ConnectionState.waiting) {
                          return SkeletonList(itemCount: 5, itemHeight: 80);
                        }
                        final docs = snap.data ?? [];
                        if (docs.isEmpty) {
                          return EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No past orders',
                            subtitle: 'Your orders will appear here',
                            accentColor: context.primaryColor,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Map<String, dynamic>> orders, String emptyTitle, String emptyDesc) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: emptyTitle,
        subtitle: emptyDesc,
        accentColor: context.primaryColor,
      );
    }

    return RefreshIndicator(
      color: context.primaryColor,
      backgroundColor: context.surfaceColor,
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (_, i) => AnimatedFadeSlide(
          delay: (i * 50).toDouble(),
          duration: const Duration(milliseconds: 400),
          child: _OrderCard(order: orders[i]),
        ),
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

    return AnimatedPressScale(
      onTap: () => context.push('/tracking/${order['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brCard,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.4),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                isDelivered
                    ? Icons.check_circle_rounded
                    : isCancelled
                        ? Icons.cancel_rounded
                        : Icons.receipt_long_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textPrimaryColor,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (itemCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$itemCount items',
                          style: GoogleFonts.inter(
                            color: context.textMutedColor,
                            fontSize: 12,
                          ),
                        ),
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
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: context.textPrimaryColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.textMutedColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
