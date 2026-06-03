import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/vendor_dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/tayyebgo_theme.dart';
import '../../widgets/responsive_layout.dart' show DashboardShell, DestItem;
import '../../widgets/shimmer_loading.dart';

class VendorDashboardScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorDashboardScreen({
    super.key,
    required this.vendorId,
    this.vendorName = 'Restaurant',
  });

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorDashboardProvider>().loadVendorDashboard(widget.vendorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final destinations = const [
      DestItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
      DestItem(label: 'Orders', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long),
      DestItem(label: 'Menu', icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book),
      DestItem(label: 'Analytics', icon: Icons.analytics_outlined, selectedIcon: Icons.analytics),
    ];

    final screens = [
      _DashboardTab(vendorId: widget.vendorId, vendorName: widget.vendorName),
      _OrdersTab(vendorId: widget.vendorId),
      _MenuTab(vendorId: widget.vendorId),
      _AnalyticsTab(vendorId: widget.vendorId),
    ];

    return DashboardShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: destinations,
      screens: screens,
      header: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: TayyebGoTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.vendorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TayyebGoTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: TayyebGoTheme.successColor),
                      SizedBox(width: 4),
                      Text('Open', style: TextStyle(fontSize: 12, color: TayyebGoTheme.successColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () => auth.logout(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final String vendorId;
  final String vendorName;

  const _DashboardTab({required this.vendorId, required this.vendorName});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorDashboardProvider>();
    final data = provider.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: TayyebGoTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good ${_greeting()}, Owner!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Here\'s your restaurant overview',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (provider.isLoading)
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: 160, child: ShimmerMetricCard()),
                SizedBox(width: 160, child: ShimmerMetricCard()),
                SizedBox(width: 160, child: ShimmerMetricCard()),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: _MetricCard(
                    icon: Icons.today,
                    label: 'Today Orders',
                    value: '${data?.todayOrders ?? 0}',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: _MetricCard(
                    icon: Icons.attach_money,
                    label: 'Revenue',
                    value: '\$${(data?.todayRevenue ?? 0).toStringAsFixed(0)}',
                    color: TayyebGoTheme.successColor,
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: _MetricCard(
                    icon: Icons.star,
                    label: 'Rating',
                    value: (data?.rating ?? 0).toStringAsFixed(1),
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Quick Actions
          const Text('Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add Product',
                color: TayyebGoTheme.primaryColor,
                onTap: () => _showAddProductSheet(context),
              ),
              _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit Info',
                color: const Color(0xFF3B82F6),
                onTap: () => _showEditInfoSheet(context),
              ),
              _ActionButton(
                icon: Icons.qr_code,
                label: 'QR Code',
                color: const Color(0xFF8B5CF6),
                onTap: () => _showQRCodeDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (data != null && data.recentOrders.isNotEmpty) ...[
            const Text('Recent Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...data.recentOrders.take(5).map((order) => _OrderCard(
                  order: order,
                  onStatusTap: () => provider.updateOrderStatus(
                      order.orderId, _nextStatus(order.status)),
                )),
          ],
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'pending':
        return 'accepted';
      case 'accepted':
        return 'preparing';
      case 'preparing':
        return 'ready_for_driver';
      case 'ready_for_driver':
        return 'picked_up';
      default:
        return current;
    }
  }

  void _showAddProductSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Main Course');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: TayyebGoTheme.bottomSheetDecoration,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Add New Product',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Product Name', hintText: 'Enter name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description', hintText: 'Enter description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Price', hintText: '0.00'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: catCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Category', hintText: 'e.g. Main Course'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        try {
                          await FirebaseFirestore.instance
                              .collection('menu_items')
                              .add({
                            'vendorId': vendorId,
                            'name': nameCtrl.text,
                            'description': descCtrl.text,
                            'price': double.tryParse(priceCtrl.text) ?? 0,
                            'category': catCtrl.text,
                            'isAvailable': true,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Product added successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed: $e'),
                                  backgroundColor: TayyebGoTheme.errorColor),
                            );
                          }
                        }
                      },
                      child: const Text('Add Product'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditInfoSheet(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '9:00 AM - 11:00 PM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: TayyebGoTheme.bottomSheetDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Edit Restaurant Info',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hoursCtrl,
              decoration: const InputDecoration(
                  labelText: 'Business Hours',
                  hintText: 'e.g. 9:00 AM - 11:00 PM'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(vendorId)
                        .update({
                      'phone': phoneCtrl.text,
                      'businessHours': hoursCtrl.text,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Info updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: TayyebGoTheme.errorColor),
                      );
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Vendor QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Icon(Icons.qr_code,
                    size: 140, color: TayyebGoTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'tayyebgo://vendor/$vendorId',
              style: const TextStyle(
                  fontSize: 12, color: TayyebGoTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: 'tayyebgo://vendor/$vendorId'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied!')),
              );
            },
            child: const Text('Copy Link'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: TayyebGoTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final VendorOrder order;
  final VoidCallback onStatusTap;

  const _OrderCard({required this.order, required this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = TayyebGoTheme.statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: TayyebGoTheme.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customer,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(order.items,
                    style: const TextStyle(
                        fontSize: 12, color: TayyebGoTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: TayyebGoTheme.primaryColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.time,
                  style: const TextStyle(
                      fontSize: 11, color: TayyebGoTheme.textMuted)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onStatusTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final String vendorId;

  const _OrdersTab({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorDashboardProvider>();
    final data = provider.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('All Orders',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '${data?.recentOrders.length ?? 0} orders',
                style: const TextStyle(
                    fontSize: 13, color: TayyebGoTheme.textSecondary),
              ),
            ],
          ),
        ),
        if (provider.isLoading)
          const Expanded(child: ShimmerList())
        else if (data == null || data.recentOrders.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: TayyebGoTheme.textMuted),
                  SizedBox(height: 16),
                  Text('No orders yet',
                      style: TextStyle(
                          fontSize: 16, color: TayyebGoTheme.textSecondary)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: data.recentOrders.length,
              itemBuilder: (context, index) {
                final order = data.recentOrders[index];
                return _OrderCard(
                  order: order,
                  onStatusTap: () => provider
                      .updateOrderStatus(
                          order.orderId, _nextStatus(order.status)),
                );
              },
            ),
          ),
      ],
    );
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'pending':
        return 'accepted';
      case 'accepted':
        return 'preparing';
      case 'preparing':
        return 'ready_for_driver';
      case 'ready_for_driver':
        return 'picked_up';
      default:
        return current;
    }
  }
}

class _MenuTab extends StatelessWidget {
  final String vendorId;

  const _MenuTab({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('menu_items')
          .where('vendorId', isEqualTo: vendorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: TayyebGoTheme.errorColor),
                const SizedBox(height: 12),
                Text('Error loading menu: ${snapshot.error}',
                    style: const TextStyle(color: TayyebGoTheme.textSecondary)),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const ShimmerList();
        }
        final items = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Menu Items',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${items.length} items',
                      style: const TextStyle(
                          fontSize: 13, color: TayyebGoTheme.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('No menu items yet',
                          style:
                              TextStyle(color: TayyebGoTheme.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item =
                            items[index].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: TayyebGoTheme.cardDecoration,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: TayyebGoTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.restaurant,
                                    color: TayyebGoTheme.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        item['name']?.toString() ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    if (item['description'] != null)
                                      Text(
                                          item['description'].toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  TayyebGoTheme.textSecondary),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(item['price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: TayyebGoTheme.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (item['isAvailable'] as bool?)
                                            ??
                                      true
                                      ? TayyebGoTheme.successColor
                                      : TayyebGoTheme.errorColor,
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

class _AnalyticsTab extends StatelessWidget {
  final String vendorId;

  const _AnalyticsTab({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorDashboardProvider>();
    final data = provider.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (provider.isLoading)
            const Column(
              children: [
                ShimmerMetricCard(),
                SizedBox(height: 12),
                ShimmerMetricCard(),
                SizedBox(height: 12),
                ShimmerMetricCard(),
              ],
            )
          else ...[
            _AnalyticsRow(
              label: 'Total Orders Today',
              value: '${data?.todayOrders ?? 0}',
              icon: Icons.shopping_bag,
            ),
            _AnalyticsRow(
              label: 'Revenue Today',
              value:
                  '\$${(data?.todayRevenue ?? 0).toStringAsFixed(2)}',
              icon: Icons.attach_money,
            ),
            _AnalyticsRow(
              label: 'Average Rating',
              value: (data?.rating ?? 0).toStringAsFixed(1),
              icon: Icons.star,
            ),
            _AnalyticsRow(
              label: 'Total Reviews',
              value: '${data?.totalReviews ?? 0}',
              icon: Icons.feedback,
            ),
            const SizedBox(height: 24),
            const Text('Order Status Breakdown',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (data != null)
              ...['pending', 'accepted', 'preparing', 'ready_for_driver', 'delivered']
                  .map((s) {
                final count = data.recentOrders
                    .where((o) => o.status == s)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: TayyebGoTheme.statusColor(s),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(s.replaceAll('_', ' '),
                          style: const TextStyle(
                              fontSize: 13,
                              color: TayyebGoTheme.textSecondary)),
                      const Spacer(),
                      Text('$count',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AnalyticsRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: TayyebGoTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: TayyebGoTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: TayyebGoTheme.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
