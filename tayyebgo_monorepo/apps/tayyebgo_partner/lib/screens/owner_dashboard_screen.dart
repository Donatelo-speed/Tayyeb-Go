import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/partner_role_controller.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<PartnerRoleController>().assertOwnerOnly();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.partnerAccent, AppColors.warning],
          ).createShader(bounds),
          child: Text('Owner Dashboard', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white)),
        ),
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: context.warningColor,
          unselectedLabelColor: context.textMutedColor,
          indicatorColor: context.warningColor,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Overview'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 20), text: 'Menu'),
            Tab(icon: Icon(Icons.delivery_dining_rounded, size: 20), text: 'Dispatch'),
            Tab(icon: Icon(Icons.local_offer_rounded, size: 20), text: 'Marketing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(restaurantId: context.read<PartnerRoleController>().restaurantId),
          _MenuTab(restaurantId: context.read<PartnerRoleController>().restaurantId),
          _DispatchTab(restaurantId: context.read<PartnerRoleController>().restaurantId),
          _MarketingTab(restaurantId: context.read<PartnerRoleController>().restaurantId),
        ],
      ),
    );
  }
}

// =============================================================================
// Overview Tab — real-time analytics
// =============================================================================

class _OverviewTab extends StatelessWidget {
  final String? restaurantId;
  const _OverviewTab({this.restaurantId});

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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (restaurantId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  Text('Restaurant Dashboard', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showRestaurantProfileDialog(context, restaurantId!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('Edit Profile', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: context.warningColor)),
                    ),
                  ),
                ]),
              ),

            // ── KPI Grid ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _kpiCard(context, 'Total Orders', '$totalOrders', Icons.shopping_bag_rounded, context.warningColor),
                _kpiCard(context, 'Daily Orders', '$dailyOrders', Icons.today_rounded, context.successColor),
                _kpiCard(context, 'Revenue', '\$${revenue.toStringAsFixed(0)}', Icons.attach_money_rounded, context.successColor),
                _kpiCard(context, 'Active', '$active', Icons.pending_actions_rounded, context.warningColor),
              ],
            ),

            if (restaurantId != null && snap.hasData && snap.data!.docs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CommissionCards(restaurantId: restaurantId!, grossRevenue: revenue),
            ],

            const SizedBox(height: 24),
            Text('Recent Orders', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: () {
                var q = FirebaseFirestore.instance.collection('orders') as Query;
                if (restaurantId != null) {
                  q = q.where('restaurantId', isEqualTo: restaurantId);
                }
                return q.orderBy('createdAt', descending: true).limit(10).snapshots();
              }(),
              builder: (context, recentSnap) {
                if (!recentSnap.hasData || recentSnap.data!.docs.isEmpty) {
                  return Text('No recent orders', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor));
                }
                return Column(
                  children: recentSnap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'] as String? ?? '';
                    return GestureDetector(
                      onTap: () => _showOrderDetailDialog(context, doc.id, d),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(d['customerName'] as String? ?? '',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                            OrderStatusBadge(status: status),
                            const SizedBox(width: 8),
                            Text('\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted)),
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
        return Row(children: [
          Expanded(child: _commissionItem(context, 'Platform Fee', '\$${commission.toStringAsFixed(0)}', context.warningColor)),
          const SizedBox(width: 12),
          Expanded(child: _commissionItem(context, 'Net Revenue', '\$${net.toStringAsFixed(0)}', context.successColor)),
        ]);
      },
    );
  }

  Widget _commissionItem(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.paid_rounded, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor)),
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
          return const Center(child: AppLoader());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return TGEmptyState(
            icon: Icons.restaurant_menu_outlined,
            title: 'No menu items yet',
            description: 'Add your first dish to get started',
            actionLabel: 'Add Dish',
            onAction: () => _showMenuItemDialog(context, null, restaurantId),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _showMenuItemDialog(context, null, restaurantId),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.warningColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Add New Dish', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              );
            }
            final doc = docs[i - 1];
            final d = doc.data() as Map<String, dynamic>;
            final name = d['name'] as String? ?? '';
            final price = (d['price'] as num?)?.toDouble() ?? 0.0;
            final stock = (d['stock'] as num?)?.toInt() ?? 100;
            final available = d['isAvailable'] as bool? ?? true;
            final category = d['category'] as String? ?? '';
            final description = d['description'] as String? ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(child: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
                              if (stock < 5) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.errorColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('Low Stock', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: context.errorColor)),
                                ),
                              ],
                            ]),
                            Text('\$${price.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0)),
                            if (category.isNotEmpty)
                              Text(category, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor)),
                            Text('Stock: $stock', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: stock < 5 ? context.errorColor : context.textSecondaryColor)),
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
                                SnackBar(content: Text('Failed to update availability: $e')),
                              );
                            }
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () => _showMenuItemDialog(context, doc, restaurantId),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.surfaceAltColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.edit_outlined, color: context.textMutedColor, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _confirmDeleteMenuItem(context, doc.id, name),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.delete_outline, color: context.errorColor, size: 18),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(description,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

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
                  SnackBar(content: Text('Failed to save menu item: $e')),
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
        TGB.destructive(label: 'Delete', isExpanded: false, onPressed: () async {
          try {
            await FirebaseFirestore.instance.collection('menu_items').doc(id).delete();
            Navigator.pop(ctx);
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Failed to delete menu item: $e')),
              );
            }
          }
        }),
      ],
    ),
  );
}

// =============================================================================
// Dispatch Tab — delivery zone toggles
// =============================================================================

class _DispatchTab extends StatelessWidget {
  final String? restaurantId;
  const _DispatchTab({this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Delivery Dispatch', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Live map & driver management', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor)),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DriverLiveMap(
              height: 280,
              showRestaurantMarkers: true,
              showOrderMarkers: true,
              restaurantId: restaurantId,
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'driver')
              .limit(200)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return TGEmptyState(
                icon: Icons.delivery_dining,
                title: 'No drivers registered',
                description: 'Drivers will appear here once they sign up',
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final displayName = d['displayName'] as String? ?? d['email'] as String? ?? 'Unknown';
                final isOnline = d['isActive'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isOnline ? context.successColor.withValues(alpha: 0.1) : context.surfaceAltColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TGAvatar(
                          initials: displayName[0].toUpperCase(),
                          size: TGAvatarSize.sm,
                          backgroundColor: isOnline ? context.successColor.withValues(alpha: 0.1) : context.surfaceAltColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('Driver', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isOnline,
                        activeColor: context.successColor,
                        onChanged: (v) async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(doc.id)
                                .update({'isActive': v});
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update driver status: $e')),
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
      ],
    );
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Promotions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
            GestureDetector(
              onTap: () => _showPromoDialog(context, restaurantId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.warningColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('New Deal', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: () {
            var q = FirebaseFirestore.instance.collection('promos').where('isActive', isEqualTo: true) as Query;
            if (restaurantId != null) {
              q = q.where('restaurantId', isEqualTo: restaurantId);
            }
            return q.snapshots();
          }(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return TGEmptyState(
                icon: Icons.local_offer_outlined,
                title: 'No active promotions',
                description: 'Create a deal to attract customers',
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final code = d['code'] as String? ?? '';
                final type = d['type'] as String? ?? '';
                final value = (d['value'] as num?)?.toDouble() ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.local_offer, color: context.warningColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(code, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('$type — ${value.toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor)),
                          ],
                        ),
                      ),
                      Switch(
                        value: d['isActive'] as bool? ?? d['active'] as bool? ?? true,
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
                                SnackBar(content: Text('Failed to update promotion: $e')),
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
      ],
    );
  }
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
              TGF(controller: valueCtrl, label: type == 'percentage' ? 'Discount %' : 'Discount Amount (\$)', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TGF(controller: minOrderCtrl, label: 'Min Order Amount (\$)', keyboardType: TextInputType.number),
            ]),
          ),
        ),
        actions: [
          TGB.ghost(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          TGB.primary(label: 'Create', isExpanded: false, onPressed: () async {
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
                  SnackBar(content: Text('Failed to create promotion: $e')),
                );
              }
            }
          }),
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
          TGB.primary(label: 'Save', isExpanded: false, onPressed: () async {
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
                  SnackBar(content: Text('Failed to save profile: $e')),
                );
              }
            }
          }),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load restaurant profile: $e')),
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
      SizedBox(width: 80, child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: context.textMutedColor))),
      Expanded(
          child: Text(value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );
}
