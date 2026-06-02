import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';



class OrdersView extends StatefulWidget {
  const OrdersView();
  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  String _statusFilter = 'all';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'preparing': return Colors.amber;
      case 'enRoute': return AppColors.primary;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'refunded': return Colors.purple;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      showAppBar: false,
      title: 'Orders Management',
        body: StreamScreenBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Orders').orderBy('createdAt', descending: true).limit(200).snapshots(),
          onLoading: () => const ShimmerLoading(itemCount: 6),
          onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
          onSuccess: (context, snapshot) {
            var docs = snapshot.docs;
            if (_statusFilter != 'all') {
              docs = docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return (d['status'] as String? ?? '') == _statusFilter;
              }).toList();
            }
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              docs = docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final id = doc.id.toLowerCase();
                final customer = (d['customerName'] as String? ?? '').toLowerCase();
                final store = (d['restaurantName'] as String? ?? '').toLowerCase();
                return id.contains(q) || customer.contains(q) || store.contains(q);
              }).toList();
            }
            if (docs.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No orders found', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                ]),
              );
            }
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by ID, customer, or store...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(tooltip: 'Clear search', icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 4),
                  _buildFilterChip('Active', 'pending'),
                  const SizedBox(width: 4),
                  _buildFilterChip('Delivered', 'delivered'),
                  const SizedBox(width: 4),
                  _buildFilterChip('Cancelled', 'cancelled'),
                  const SizedBox(width: 4),
                  _buildFilterChip('Refunded', 'refunded'),
                ]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${docs.length} orders', style: AppTypography.caption),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final customerName = d['customerName'] as String? ?? d['userId'] as String? ?? 'Unknown';
                    final storeName = d['restaurantName'] as String? ?? d['restaurantId'] as String? ?? 'Unknown';
                    final driverName = d['driverName'] as String? ?? '-';
                    final status = d['status'] as String? ?? 'pending';
                    final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
                    final paymentMethod = d['paymentMethod'] as String? ?? 'unknown';
                    final createdAt = d['createdAt'] as Timestamp?;
                    final statusLabel = status[0].toUpperCase() + status.substring(1);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: TayyebGoTheme.cardDecoration,
                      child: Row(children: [
                        Expanded(
                          flex: 2,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('#' + id.substring(0, id.length > 8 ? 8 : id.length), style: AppTypography.bodyBold),
                            Text(storeName, style: AppTypography.caption),
                          ]),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(customerName, style: AppTypography.body),
                            Text(driverName, style: AppTypography.caption),
                          ]),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(status))),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('\$${amount.toStringAsFixed(2)}', style: AppTypography.bodyBold),
                            Text(paymentMethod, style: AppTypography.small),
                          ]),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(createdAt != null ? _formatDate(createdAt.toDate()) : '-', style: AppTypography.caption),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'refund') _refundOrder(context, id, amount);
                            if (v == 'reassign') _showReassignDialog(context, id);
                            if (v == 'contact') _showContactDialog(context, customerName);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility, size: 20), title: Text('View'))),
                            if (status == 'delivered')
                              const PopupMenuItem(value: 'refund', child: ListTile(leading: Icon(Icons.money_off, size: 20, color: Colors.orange), title: Text('Refund'))),
                            if (status == 'pending' || status == 'accepted')
                              const PopupMenuItem(value: 'reassign', child: ListTile(leading: Icon(Icons.swap_horiz, size: 20), title: Text('Reassign Driver'))),
                            const PopupMenuItem(value: 'contact', child: ListTile(leading: Icon(Icons.message, size: 20), title: Text('Contact Customer'))),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _refundOrder(BuildContext context, String orderId, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refund Order'),
        content: Text('Process refund of \$${amount.toStringAsFixed(2)} for order #${orderId.substring(0, 8)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({
                  'status': 'refunded',
                  'refundedAt': FieldValue.serverTimestamp(),
                  'refundedAmount': amount,
                });
                await FirebaseFirestore.instance.collection('activity_log').add({
                  'text': 'Order #${orderId.substring(0, 8)} refunded (\$${amount.toStringAsFixed(2)})',
                  'color': 'orange',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) ctx.showSuccess('Refund processed: \$${amount.toStringAsFixed(2)}');
                Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) ctx.showError('Refund failed');
              }
            },
            child: const Text('Process Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog(BuildContext context, String orderId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign Driver'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter new driver ID to reassign this order:'),
          const SizedBox(height: 12),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Driver ID', hintText: 'Enter driver UID...')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({
                    'driverId': ctrl.text.trim(),
                    'reassignedAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) ctx.showSuccess('Driver reassigned');
                  Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ctx.showError('Failed to reassign driver');
                }
              }
            },
            child: const Text('Reassign'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context, String customerName) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contact $customerName'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Type your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Message sent (simulated)'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
