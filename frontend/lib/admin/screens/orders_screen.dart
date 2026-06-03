import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _search = '';
  String _statusFilter = 'all';

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const statuses = ['all', 'pending', 'accepted', 'preparing', 'ready_for_driver', 'picked_up', 'delivered', 'cancelled'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoadingState();
        if (snap.hasError) return AdminErrorState(message: snap.error.toString(), onRetry: () => setState(() {}));
        if (!snap.hasData) return const AdminLoadingState();

        var docs = snap.data!.docs;
        if (_search.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map;
            final id = d.id.toLowerCase();
            final name = (data['customerName'] as String? ?? '').toLowerCase();
            final q = _search.toLowerCase();
            return id.contains(q) || name.contains(q);
          }).toList();
        }
        if (_statusFilter != 'all') {
          docs = docs.where((d) => (d.data() as Map)['status'] == _statusFilter).toList();
        }

        return Column(children: [
          AdminSectionHeader(
            title: 'Orders',
            count: docs.length,
            searchHint: 'Search by ID or customer...',
            onSearch: (v) => setState(() => _search = v),
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
                ? const AdminEmptyState(icon: Icons.receipt_long_rounded, title: 'No orders found', subtitle: 'Orders will appear here as customers place them')
                : ListView.builder(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final status = d['status'] as String? ?? 'pending';
                      final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
                      final customer = d['customerName'] as String? ?? 'Unknown';
                      final store = d['storeName'] ?? d['restaurantName'] as String? ?? 'Unknown';
                      final items = d['items'] as List? ?? [];
                      final method = d['paymentMethod'] as String? ?? 'cash';
                      final created = (d['createdAt'] as Timestamp?)?.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        padding: const EdgeInsets.all(AdminSpacing.lg),
                        decoration: cardDecoration(isDark),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AdminColors.statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)),
                            child: Center(child: Text('#${docs[i].id.substring(0, min(4, docs[i].id.length))}', style: AdminTypography.mono(isDark))),
                          ),
                          const SizedBox(width: AdminSpacing.lg),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text('$customer  ·  $store', style: AdminTypography.h4(isDark)),
                              const SizedBox(width: AdminSpacing.sm),
                              AdminStatusBadge(status: status),
                            ]),
                            const SizedBox(height: 4),
                            Text('${items.length} items  ·  \$${amount.toStringAsFixed(2)}  ·  $method', style: AdminTypography.bodySmall(isDark)),
                            if (created != null) Text(timeAgo(created), style: AdminTypography.caption(isDark)),
                          ])),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18),
                            onSelected: (v) => _updateStatus(docs[i].id, v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'pending', child: Text('Pending')),
                              PopupMenuItem(value: 'accepted', child: Text('Accepted')),
                              PopupMenuItem(value: 'preparing', child: Text('Preparing')),
                              PopupMenuItem(value: 'ready_for_driver', child: Text('Ready for Driver')),
                              PopupMenuItem(value: 'picked_up', child: Text('Picked Up')),
                              PopupMenuItem(value: 'delivered', child: Text('Delivered')),
                              PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
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
}