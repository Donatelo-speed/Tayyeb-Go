import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/partner_role_controller.dart';

/// Owner Dashboard — comprehensive restaurant management suite.
///
/// Tabs:
///   0. Overview — daily revenue, active orders, charts
///   1. Menu — product inventory with add/edit/remove
///   2. Dispatch — live delivery toggles
///   3. Marketing — deals and promotions manager
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
      backgroundColor: TayyebGoTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (v) async {
              if (v == 'profile') {
                context.go('/profile');
              } else if (v == 'settings') {
                context.go('/settings');
              } else if (v == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Sign Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.menu_book), text: 'Menu'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Dispatch'),
            Tab(icon: Icon(Icons.local_offer), text: 'Marketing'),
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
    var ordersQuery = FirebaseFirestore.instance.collection('Orders') as Query;
    if (restaurantId != null) {
      ordersQuery = ordersQuery.where('restaurantId', isEqualTo: restaurantId);
    }
    ordersQuery = ordersQuery.limit(500);
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
                  Text('Restaurant Dashboard', style: TayyebGoTheme.heading2),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    onPressed: () => _showRestaurantProfileDialog(context, restaurantId!),
                  ),
                ]),
              ),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _AnalyticCard(
                title: 'Total Orders',
                value: '$totalOrders',
                icon: Icons.shopping_bag,
                color: Colors.blue,
              ),
              _AnalyticCard(
                title: 'Daily Orders',
                value: '$dailyOrders',
                icon: Icons.today,
                color: Colors.teal,
              ),
              _AnalyticCard(
                title: 'Revenue',
                value: '\$${revenue.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              _AnalyticCard(
                title: 'Active Orders',
                value: '$active',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              _AnalyticCard(
                title: 'Avg Order Value',
                value: totalOrders > 0
                    ? '\$${(revenue / totalOrders).toStringAsFixed(1)}'
                    : '\$0',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
              if (restaurantId != null && snap.hasData && snap.data!.docs.isNotEmpty) ...[
                _CommissionCards(restaurantId: restaurantId!, grossRevenue: revenue),
              ],
            ]),
            const SizedBox(height: 24),
            Text('Recent Orders', style: TayyebGoTheme.heading3),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: () {
                var q = FirebaseFirestore.instance.collection('Orders') as Query;
                if (restaurantId != null) {
                  q = q.where('restaurantId', isEqualTo: restaurantId);
                }
                return q.orderBy('createdAt', descending: true).limit(5).snapshots();
              }(),
              builder: (context, recentSnap) {
                if (!recentSnap.hasData || recentSnap.data!.docs.isEmpty) {
                  return Text('No recent orders', style: TayyebGoTheme.caption);
                }
                return Column(
                  children: recentSnap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: TayyebGoTheme.cardDecoration,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
                        onTap: () => _showOrderDetailDialog(context, doc.id, d),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(d['customerName'] as String? ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            OrderStatusBadge(status: status),
                            const SizedBox(width: 8),
                            Text('\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
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
}

class _AnalyticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TayyebGoTheme.heading2),
          Text(title, style: TayyebGoTheme.caption),
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
      stream: FirebaseFirestore.instance.collection('Restaurants').doc(restaurantId).snapshots(),
      onSuccess: (context, snap) {
        final percent = (snap.data() as Map<String, dynamic>?)?['commissionPercent'] as num? ?? 15.0;
        final commission = grossRevenue * percent.toDouble() / 100;
        final net = grossRevenue - commission;
        return Row(children: [
          _AnalyticCard(
            title: 'Platform Fee (${percent.toInt()}%)',
            value: '\$${commission.toStringAsFixed(0)}',
            icon: Icons.paid,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _AnalyticCard(
            title: 'Net Revenue',
            value: '\$${net.toStringAsFixed(0)}',
            icon: Icons.account_balance,
            color: Colors.teal,
          ),
        ]);
      },
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
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu_outlined,
                    size: 64, color: TayyebGoTheme.textMuted),
                const SizedBox(height: 16),
                Text('No menu items yet',
                    style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showMenuItemDialog(context, null, restaurantId),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Dish'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: () => _showMenuItemDialog(context, null, restaurantId),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Dish'),
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
              decoration: TayyebGoTheme.cardDecoration,
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
                              Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                              if (stock < 5) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Low Stock',
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ]),
                            Text('\$${price.toStringAsFixed(2)}', style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13)),
                            if (category.isNotEmpty)
                              Text(category, style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 11)),
                            Text('Stock: $stock', style: TextStyle(color: stock < 5 ? Colors.red : TayyebGoTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: available,
                        activeColor: TayyebGoTheme.successColor,
                        onChanged: (v) => FirebaseFirestore.instance
                            .collection('menu_items')
                            .doc(doc.id)
                            .update({'isAvailable': v}),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showMenuItemDialog(context, doc, restaurantId),
                        color: TayyebGoTheme.textMuted,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _confirmDeleteMenuItem(context, doc.id, name),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(description, style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
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
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), textCapitalization: TextCapitalization.sentences, maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price', prefixText: '\$'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category'), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: sortOrderCtrl, decoration: const InputDecoration(labelText: 'Sort Order'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
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
            if (isEdit) {
              coll.doc(existing.id).update(data);
            } else {
              coll.add(data);
            }
            Navigator.pop(ctx);
          },
          child: Text(isEdit ? 'Update' : 'Create'),
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
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () { FirebaseFirestore.instance.collection('menu_items').doc(id).delete(); Navigator.pop(ctx); },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
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
        Text('Delivery Dispatch', style: TayyebGoTheme.heading3),
        const SizedBox(height: 8),
        Text('Live map & driver management',
            style: TayyebGoTheme.caption),
        const SizedBox(height: 16),
        DriverLiveMap(
          height: 280,
          showRestaurantMarkers: true,
          showOrderMarkers: true,
          restaurantId: restaurantId,
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('role', isEqualTo: 'driver')
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No drivers registered',
                      style: TextStyle(color: TayyebGoTheme.textMuted)),
                ),
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final displayName = d['displayName'] as String? ?? d['email'] as String? ?? 'Unknown';
                final isOnline = d['isActive'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: TayyebGoTheme.cardDecoration,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (isOnline ? TayyebGoTheme.successColor : TayyebGoTheme.textMuted)
                            .withValues(alpha: 0.1),
                        child: Icon(Icons.delivery_dining,
                            color: isOnline ? TayyebGoTheme.successColor : TayyebGoTheme.textMuted,
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Driver',
                                style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isOnline,
                        activeColor: TayyebGoTheme.successColor,
                        onChanged: (v) => FirebaseFirestore.instance
                            .collection('Users')
                            .doc(doc.id)
                            .update({'isActive': v}),
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
            Text('Active Promotions', style: TayyebGoTheme.heading3),
            ElevatedButton.icon(
              onPressed: () => _showPromoDialog(context, restaurantId),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Deal'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: () {
            var q = FirebaseFirestore.instance.collection('promos').where('active', isEqualTo: true) as Query;
            if (restaurantId != null) {
              q = q.where('restaurantId', isEqualTo: restaurantId);
            }
            return q.snapshots();
          }(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_offer_outlined, size: 48, color: TayyebGoTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('No active promotions', style: TextStyle(color: TayyebGoTheme.textMuted)),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: TayyebGoTheme.cardDecoration,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: TayyebGoTheme.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.local_offer, color: TayyebGoTheme.warningColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('$type — ${value.toStringAsFixed(0)}%',
                                    style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: d['active'] as bool? ?? true,
                            activeColor: TayyebGoTheme.successColor,
                            onChanged: (v) => FirebaseFirestore.instance
                                .collection('promos')
                                .doc(doc.id)
                                .update({'active': v}),
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
  bool active = true;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) => AlertDialog(
        title: const Text('New Promotion'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Coupon Code', hintText: 'SUMMER20'), textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [DropdownMenuItem(value: 'percentage', child: Text('Percentage')), DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount'))],
                onChanged: (v) => setLocalState(() => type = v ?? 'percentage'),
              ),
              const SizedBox(height: 12),
              TextField(controller: valueCtrl, decoration: InputDecoration(labelText: type == 'percentage' ? 'Discount %' : 'Discount Amount (\$)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: minOrderCtrl, decoration: const InputDecoration(labelText: 'Min Order Amount (\$)'), keyboardType: TextInputType.number),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (codeCtrl.text.trim().isEmpty) return;
              FirebaseFirestore.instance.collection('promos').add({
                'code': codeCtrl.text.trim().toUpperCase(),
                'type': type,
                'value': double.tryParse(valueCtrl.text.trim()) ?? 10,
                'minOrder': double.tryParse(minOrderCtrl.text.trim()) ?? 0,
                'active': active,
                if (restaurantId != null) 'restaurantId': restaurantId,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}

void _showRestaurantProfileDialog(BuildContext context, String restaurantId) {
  FirebaseFirestore.instance.collection('Restaurants').doc(restaurantId).get().then((snap) {
    if (!snap.exists) return;
    final d = snap.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: d['name'] as String? ?? '');
    final cuisineCtrl = TextEditingController(text: d['cuisineType'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: d['phone'] as String? ?? '');
    final streetCtrl = TextEditingController(text: d['street'] as String? ?? '');
    final cityCtrl = TextEditingController(text: d['city'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Restaurant Profile'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: cuisineCtrl, decoration: const InputDecoration(labelText: 'Cuisine'), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: streetCtrl, decoration: const InputDecoration(labelText: 'Street'), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City'), textCapitalization: TextCapitalization.words),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('Restaurants').doc(restaurantId).update({
                'name': nameCtrl.text.trim(),
                'cuisineType': cuisineCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'street': streetCtrl.text.trim(),
                'city': cityCtrl.text.trim(),
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  });
}

void _showOrderDetailDialog(BuildContext context, String orderId, Map<String, dynamic> d) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detailRow('Customer', d['customerName'] as String? ?? ''),
          _detailRow('Phone', d['customerPhone'] as String? ?? ''),
          _detailRow('Type', d['fulfillmentType'] as String? ?? ''),
          _detailRow('Status', d['status'] as String? ?? ''),
          _detailRow('Total', '\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}'),
          if (d['deliveryAddress'] is Map)
            _detailRow('Address', (d['deliveryAddress'] as Map)['fullAddress'] as String? ?? ''),
          if (d['items'] is List) ...[
            const Divider(height: 24),
            Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(d['items'] as List).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${item['quantity']}x ${item['name']} - \$${(item['price'] as num?)?.toDouble() ?? 0}', style: TextStyle(fontSize: 13)),
            )),
          ],
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}
