import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/partner_role_controller.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    context.read<PartnerRoleController>().assertOwnerOnly();
    final restaurantId = context.read<PartnerRoleController>().restaurantId;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: IndexedStack(
        index: _currentTab,
        children: [
          _DashboardTab(restaurantId: restaurantId),
          _MenuTab(restaurantId: restaurantId),
          _OrdersTab(restaurantId: restaurantId),
          _MarketingTab(restaurantId: restaurantId),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(
            top: BorderSide(
              color: context.borderColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isActive: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0),
                ),
                _NavItem(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Menu',
                  isActive: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  isActive: _currentTab == 2,
                  onTap: () => setState(() => _currentTab = 2),
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: 'Marketing',
                  isActive: _currentTab == 3,
                  onTap: () => setState(() => _currentTab = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom Nav Item
// =============================================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.partnerAccent : context.textMutedColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.partnerAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Dashboard Tab — KPIs, quick actions, recent orders
// =============================================================================

class _DashboardTab extends StatelessWidget {
  final String? restaurantId;
  const _DashboardTab({this.restaurantId});

  @override
  Widget build(BuildContext context) {
    var ordersQuery = FirebaseFirestore.instance.collection('orders') as Query;
    if (restaurantId != null) {
      ordersQuery = ordersQuery.where('restaurantId', isEqualTo: restaurantId);
    }
    ordersQuery = ordersQuery.limit(500).orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: ordersQuery.snapshots(),
      builder: (context, snap) {
        final totalOrders = snap.hasData ? snap.data!.docs.length : 0;
        double revenue = 0;
        int active = 0;
        int dailyOrders = 0;
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            revenue += (d['totalAmount'] as num?)?.toDouble() ?? 0;
            final status = d['status'] as String?;
            if (status != 'delivered' && status != 'cancelled') {
              active++;
            }
            final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null && createdAt.isAfter(todayStart) && createdAt.isBefore(todayEnd)) {
              dailyOrders++;
            }
          }
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.partnerAccent, Color(0xFFFCD34D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Partner Dashboard',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Text(
                                'Manage your restaurant',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: context.textMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (restaurantId != null)
                          GestureDetector(
                            onTap: () => _showRestaurantProfileDialog(context, restaurantId!),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.borderColor.withValues(alpha: 0.3)),
                              ),
                              child: Icon(Icons.edit_rounded, color: context.textMutedColor, size: 18),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Overview',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _KpiCard(
                      label: 'Total Orders',
                      value: '$totalOrders',
                      icon: Icons.shopping_bag_rounded,
                      color: AppColors.partnerAccent,
                    ),
                    _KpiCard(
                      label: 'Today',
                      value: '$dailyOrders',
                      icon: Icons.today_rounded,
                      color: AppColors.driverAccent,
                    ),
                    _KpiCard(
                      label: 'Revenue',
                      value: '\$${revenue.toStringAsFixed(0)}',
                      icon: Icons.attach_money_rounded,
                      color: AppColors.primary,
                    ),
                    _KpiCard(
                      label: 'Active',
                      value: '$active',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
            if (restaurantId != null && snap.hasData && snap.data!.docs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _CommissionCards(restaurantId: restaurantId!, grossRevenue: revenue),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Recent Orders',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (restaurantId != null)
                      GestureDetector(
                        onTap: () => context.push('/analytics'),
                        child: Text(
                          'View All',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.partnerAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: () {
                    var q = FirebaseFirestore.instance.collection('orders') as Query;
                    if (restaurantId != null) {
                      q = q.where('restaurantId', isEqualTo: restaurantId);
                    }
                    return q.orderBy('createdAt', descending: true).limit(10).snapshots();
                  }(),
                  builder: (context, recentSnap) {
                    if (!recentSnap.hasData || recentSnap.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 40, color: context.textMutedColor),
                              const SizedBox(height: 12),
                              Text(
                                'No orders yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.textMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: recentSnap.data!.docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final status = d['status'] as String? ?? '';
                        final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
                        final customerName = d['customerName'] as String? ?? 'Customer';
                        final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
                        final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';

                        return GestureDetector(
                          onTap: () => _showOrderDetailDialog(context, doc.id, d),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.partnerAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      customerName[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      if (timeAgo.isNotEmpty)
                                        Text(
                                          timeAgo,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: context.textMutedColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${amount.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    OrderStatusBadge(status: status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }

  static String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionCards extends StatelessWidget {
  final String restaurantId;
  final double grossRevenue;
  const _CommissionCards({required this.restaurantId, required this.grossRevenue});

  @override
  Widget build(BuildContext context) {
    return StreamScreenBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).snapshots(),
      onSuccess: (context, snap) {
        final percent = (snap.data() as Map<String, dynamic>?)?['commissionPercent'] as num? ?? 15.0;
        final commission = grossRevenue * percent.toDouble() / 100;
        final net = grossRevenue - commission;
        return Row(
          children: [
            Expanded(
              child: _commissionItem(context, 'Platform Fee', '\$${commission.toStringAsFixed(0)}', context.warningColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _commissionItem(context, 'Net Revenue', '\$${net.toStringAsFixed(0)}', context.successColor),
            ),
          ],
        );
      },
    );
  }

  Widget _commissionItem(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.paid_rounded, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: context.textPrimaryColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Menu Tab — product inventory management
// =============================================================================

class _MenuTab extends StatelessWidget {
  final String? restaurantId;
  const _MenuTab({this.restaurantId});

  @override
  Widget build(BuildContext context) {
    var menuQuery = FirebaseFirestore.instance.collection('menu_items') as Query;
    if (restaurantId != null) {
      menuQuery = menuQuery.where('restaurantId', isEqualTo: restaurantId);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: menuQuery.orderBy('sortOrder').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: AppLoader());
        }
        final docs = snapshot.data!.docs;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu Management',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          Text(
                            '${docs.length} items',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.textMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showMenuItemDialog(context, null, restaurantId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.partnerAccent, Color(0xFFFCD34D)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Add Item',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (docs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu_outlined, size: 56, color: context.textMutedColor),
                      const SizedBox(height: 16),
                      Text(
                        'No menu items yet',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first dish to get started',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final name = d['name'] as String? ?? '';
                    final price = (d['price'] as num?)?.toDouble() ?? 0.0;
                    final stock = (d['stock'] as num?)?.toInt() ?? 100;
                    final available = d['isAvailable'] as bool? ?? true;
                    final category = d['category'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.partnerAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.partnerAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (stock < 5) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.errorColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Low',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: context.errorColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '\$${price.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.partnerAccent,
                                      ),
                                    ),
                                    if (category.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.surfaceAltColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          category,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: context.textMutedColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: available,
                            activeColor: context.successColor,
                            onChanged: (v) async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('menu_items')
                                    .doc(doc.id)
                                    .update({'isAvailable': v});
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showMenuItemDialog(context, doc, restaurantId),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: context.surfaceAltColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.edit_outlined, color: context.textMutedColor, size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _confirmDeleteMenuItem(context, doc.id, name),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: context.errorColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.delete_outline, color: context.errorColor, size: 16),
                            ),
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
    );
  }
}

// =============================================================================
// Orders Tab — active orders with live updates
// =============================================================================

class _OrdersTab extends StatelessWidget {
  final String? restaurantId;
  const _OrdersTab({this.restaurantId});

  @override
  Widget build(BuildContext context) {
    var ordersQuery = FirebaseFirestore.instance.collection('orders') as Query;
    if (restaurantId != null) {
      ordersQuery = ordersQuery.where('restaurantId', isEqualTo: restaurantId);
    }
    ordersQuery = ordersQuery
        .where('status', whereIn: ['placed', 'accepted', 'preparing', 'ready', 'ready_for_driver'] as List<Object?>)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: ordersQuery.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Orders',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '${docs.length} orders in progress',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (docs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 56, color: context.textMutedColor),
                      const SizedBox(height: 16),
                      Text(
                        'No active orders',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Orders will appear here when customers place them',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'] as String? ?? '';
                    final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
                    final customerName = d['customerName'] as String? ?? 'Customer';
                    final items = d['items'] as List? ?? [];
                    final itemCount = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));

                    final statusColor = _orderStatusColor(status, context);

                    return GestureDetector(
                      onTap: () => _showOrderDetailDialog(context, doc.id, d),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\$${amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.partnerAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      customerName[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.partnerAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: context.textMutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  static Color _orderStatusColor(String status, BuildContext context) {
    switch (status) {
      case 'placed':
        return context.warningColor;
      case 'accepted':
        return AppColors.driverAccent;
      case 'preparing':
        return AppColors.primary;
      case 'ready':
        return context.successColor;
      case 'ready_for_driver':
        return AppColors.partnerAccent;
      default:
        return context.textMutedColor;
    }
  }
}

// =============================================================================
// Marketing Tab — deals and promotions manager
// =============================================================================

class _MarketingTab extends StatelessWidget {
  final String? restaurantId;
  const _MarketingTab({this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marketing',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Manage promotions and deals',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showPromoDialog(context, restaurantId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.partnerAccent, Color(0xFFFCD34D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'New Deal',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: StreamBuilder<QuerySnapshot>(
              stream: () {
                var q = FirebaseFirestore.instance.collection('promos') as Query;
                if (restaurantId != null) {
                  q = q.where('restaurantId', isEqualTo: restaurantId);
                }
                return q.orderBy('createdAt', descending: true).snapshots();
              }(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.local_offer_outlined, size: 40, color: context.textMutedColor),
                          const SizedBox(height: 12),
                          Text(
                            'No promotions yet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a deal to attract customers',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.textMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final code = d['code'] as String? ?? '';
                    final type = d['type'] as String? ?? '';
                    final value = (d['value'] as num?)?.toDouble() ?? 0;
                    final isActive = d['isActive'] as bool? ?? d['active'] as bool? ?? true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? AppColors.partnerAccent.withValues(alpha: 0.3)
                              : context.borderColor.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (isActive ? AppColors.partnerAccent : context.textMutedColor).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.local_offer,
                              color: isActive ? AppColors.partnerAccent : context.textMutedColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  code,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  '$type — ${value.toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: context.textMutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeColor: context.successColor,
                            onChanged: (v) async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('promos')
                                    .doc(doc.id)
                                    .update({'isActive': v, 'active': v});
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// =============================================================================
// Dialogs
// =============================================================================

void _showMenuItemDialog(BuildContext context, DocumentSnapshot? existing, String? restaurantId) {
  final d = existing?.data() as Map<String, dynamic>?;
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: d?['name'] as String? ?? '');
  final descCtrl = TextEditingController(text: d?['description'] as String? ?? '');
  final priceCtrl = TextEditingController(text: (d?['price'] as num?)?.toString() ?? '');
  final categoryCtrl = TextEditingController(text: d?['category'] as String? ?? '');
  final sortOrderCtrl = TextEditingController(text: (d?['sortOrder'] as num?)?.toString() ?? '0');
  final stockCtrl = TextEditingController(text: (d?['stock'] as num?)?.toString() ?? '100');

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TGF(controller: nameCtrl, label: 'Name', textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TGF(controller: descCtrl, label: 'Description', textCapitalization: TextCapitalization.sentences, maxLines: 2),
            const SizedBox(height: 12),
            TGF(controller: priceCtrl, label: 'Price', hint: '\$0.00', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TGF(controller: categoryCtrl, label: 'Category', textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TGF(controller: sortOrderCtrl, label: 'Sort Order', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TGF(controller: stockCtrl, label: 'Stock', keyboardType: TextInputType.number),
          ]),
        ),
      ),
      actions: [
        TGB.ghost(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
        TGB.primary(
          label: isEdit ? 'Update' : 'Create',
          isExpanded: false,
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
            final data = <String, dynamic>{
              'name': nameCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
              'category': categoryCtrl.text.trim(),
              'sortOrder': int.tryParse(sortOrderCtrl.text.trim()) ?? 0,
              'stock': int.tryParse(stockCtrl.text.trim()) ?? 100,
              'isAvailable': d?['isAvailable'] as bool? ?? true,
            };
            if (!isEdit && restaurantId != null) {
              data['restaurantId'] = restaurantId;
            }
            final coll = FirebaseFirestore.instance.collection('menu_items');
            try {
              if (isEdit) {
                await coll.doc(existing.id).update(data);
              } else {
                await coll.add(data);
              }
              Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed to save: $e')),
                );
              }
            }
          },
        ),
      ],
    ),
  );
}

void _confirmDeleteMenuItem(BuildContext context, String id, String name) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Menu Item'),
      content: Text('Delete "$name"?'),
      actions: [
        TGB.ghost(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
        TGB.destructive(
          label: 'Delete',
          isExpanded: false,
          onPressed: () async {
            try {
              await FirebaseFirestore.instance.collection('menu_items').doc(id).delete();
              Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            }
          },
        ),
      ],
    ),
  );
}

void _showPromoDialog(BuildContext context, String? restaurantId) {
  final codeCtrl = TextEditingController();
  final valueCtrl = TextEditingController(text: '10');
  final minOrderCtrl = TextEditingController(text: '0');
  String type = 'percentage';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) => AlertDialog(
        title: const Text('New Promotion'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TGF(controller: codeCtrl, label: 'Coupon Code', hint: 'SUMMER20', textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                ],
                onChanged: (v) => setLocalState(() => type = v ?? 'percentage'),
              ),
              const SizedBox(height: 12),
              TGF(controller: valueCtrl, label: type == 'percentage' ? 'Discount %' : 'Amount (\$)', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TGF(controller: minOrderCtrl, label: 'Min Order (\$)', keyboardType: TextInputType.number),
            ]),
          ),
        ),
        actions: [
          TGB.ghost(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          TGB.primary(
            label: 'Create',
            isExpanded: false,
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              try {
                final code = codeCtrl.text.trim().toUpperCase();
                final value = double.tryParse(valueCtrl.text.trim()) ?? 10;
                final minOrder = double.tryParse(minOrderCtrl.text.trim()) ?? 0;
                await FirebaseFirestore.instance.collection('promos').add({
                  'code': code,
                  'type': type,
                  'value': value,
                  'minOrder': minOrder,
                  'minOrderAmount': minOrder,
                  'active': true,
                  'isActive': true,
                  if (restaurantId != null) 'restaurantId': restaurantId,
                  'usageCount': 0,
                  'usageLimit': 0,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

void _showRestaurantProfileDialog(BuildContext context, String restaurantId) async {
  try {
    final snap = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get();
    if (!snap.exists) return;
    final d = snap.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: d['name'] as String? ?? '');
    final cuisineCtrl = TextEditingController(text: d['cuisineType'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: d['phone'] as String? ?? '');
    final streetCtrl = TextEditingController(text: d['street'] as String? ?? '');
    final cityCtrl = TextEditingController(text: d['city'] as String? ?? '');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Restaurant Profile'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TGF(controller: nameCtrl, label: 'Name', textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TGF(controller: cuisineCtrl, label: 'Cuisine', textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TGF(controller: phoneCtrl, label: 'Phone', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TGF(controller: streetCtrl, label: 'Street', textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TGF(controller: cityCtrl, label: 'City', textCapitalization: TextCapitalization.words),
            ]),
          ),
        ),
        actions: [
          TGB.ghost(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          TGB.primary(
            label: 'Save',
            isExpanded: false,
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).update({
                  'name': nameCtrl.text.trim(),
                  'cuisineType': cuisineCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'street': streetCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                });
                Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }
}

void _showOrderDetailDialog(BuildContext context, String orderId, Map<String, dynamic> d) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(ctx, 'Customer', d['customerName'] as String? ?? ''),
            _detailRow(ctx, 'Phone', d['customerPhone'] as String? ?? ''),
            _detailRow(ctx, 'Type', d['fulfillmentType'] as String? ?? ''),
            _detailRow(ctx, 'Status', d['status'] as String? ?? ''),
            _detailRow(ctx, 'Total', '\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}'),
            if (d['deliveryAddress'] is Map)
              _detailRow(ctx, 'Address', (d['deliveryAddress'] as Map)['fullAddress'] as String? ?? ''),
            if (d['items'] is List) ...[
              const Divider(height: 24),
              Text('Items', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...(d['items'] as List).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${item['quantity']}x ${item['name']} - \$${(item['price'] as num?)?.toDouble() ?? 0}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              )),
            ],
          ],
        ),
      ),
      actions: [
        TGB.ghost(label: 'Close', onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );
}

Widget _detailRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ]),
  );
}
