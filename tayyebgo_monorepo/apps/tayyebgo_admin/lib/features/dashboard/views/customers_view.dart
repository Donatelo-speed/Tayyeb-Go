import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class CustomersView extends StatefulWidget {
  const CustomersView();
  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      showAppBar: false,
      title: 'Customers',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customers by name or email...',
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
          Expanded(
            child: StreamScreenBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').limit(500).snapshots(),
              onLoading: () => const ShimmerLoading(itemCount: 6),
              onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
              onSuccess: (context, snapshot) {
                var docs = snapshot.docs;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = (d['displayName'] as String? ?? '').toLowerCase();
                    final email = (d['email'] as String? ?? '').toLowerCase();
                    return name.contains(q) || email.contains(q);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.people_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('No customers yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final displayName = d['displayName'] as String? ?? d['email'] as String? ?? 'Unknown';
                    final email = d['email'] as String? ?? '';
                    final phone = d['phone'] as String? ?? '-';
                    final isActive = d['isActive'] as bool? ?? true;
                    final ordersCount = (d['ordersCount'] as num?)?.toInt() ?? 0;
                    final totalSpending = (d['totalSpending'] as num?)?.toDouble() ?? 0;
                    final avgRating = (d['avgRating'] as num?)?.toDouble() ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: TayyebGoTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: AppTypography.bodyBold),
                                  Row(children: [
                                    Text(email, style: AppTypography.caption),
                                    if (phone != '-') ...[
                                      const SizedBox(width: 8),
                                      Text(phone, style: AppTypography.caption),
                                    ],
                                  ]),
                                ],
                              ),
                            ),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('Suspended', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'view') _showCustomerDetails(context, id, d);
                                if (v == 'suspend') _toggleCustomerStatus(id, !isActive);
                                if (v == 'contact') _showContactCustomer(context, displayName);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility, size: 20), title: Text('View Profile'))),
                                PopupMenuItem(value: 'suspend', child: ListTile(
                                  leading: Icon(isActive ? Icons.block : Icons.check_circle, size: 20, color: isActive ? Colors.orange : AppColors.success),
                                  title: Text(isActive ? 'Suspend' : 'Activate'),
                                )),
                                const PopupMenuItem(value: 'contact', child: ListTile(leading: Icon(Icons.message, size: 20), title: Text('Contact'))),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _customerStat(Icons.shopping_bag, '$ordersCount', 'Orders', Colors.blue),
                            const SizedBox(width: 24),
                            _customerStat(Icons.attach_money, '\$${totalSpending.toStringAsFixed(0)}', 'Spent', Colors.green),
                            const SizedBox(width: 24),
                            _customerStat(Icons.star, avgRating > 0 ? avgRating.toStringAsFixed(1) : '-', 'Rating', Colors.amber),
                          ]),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _customerStat(IconData icon, String value, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      const SizedBox(width: 4),
      Text(label, style: AppTypography.small),
    ]);
  }

  void _showCustomerDetails(BuildContext context, String uid, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d['displayName'] as String? ?? 'Customer'),
        content: SizedBox(
          width: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).limit(20).snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.hasError) {
                return Text('Error loading orders: ${orderSnap.error}', style: const TextStyle(color: Colors.red));
              }
              int refundCount = 0;
              if (orderSnap.hasData) {
                refundCount = orderSnap.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'refunded').length;
              }
              return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Email: ${d['email'] as String? ?? 'N/A'}', style: AppTypography.body),
                Text('Phone: ${d['phone'] as String? ?? 'N/A'}', style: AppTypography.body),
                const Divider(),
                Text('Orders: ${orderSnap.hasData ? orderSnap.data!.docs.length : 0}', style: AppTypography.bodyBold),
                Text('Refunds: $refundCount', style: AppTypography.body),
                Text('Total Spent: \$${((d['totalSpending'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}', style: AppTypography.bodyBold),
                if (orderSnap.hasData && orderSnap.data!.docs.isNotEmpty) ...[
                  const Divider(),
                  Text('Recent Orders', style: AppTypography.heading3),
                  const SizedBox(height: 8),
                  ...orderSnap.data!.docs.take(5).map((doc) {
                    final od = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      title: Text(od['restaurantName'] as String? ?? 'Store'),
                      trailing: Text('\$${((od['totalAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}'),
                    );
                  }),
                ],
              ]);
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _toggleCustomerStatus(String docId, bool active) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({'isActive': active});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(active ? 'Account activated' : 'Account suspended'),
          backgroundColor: active ? AppColors.success : Colors.orange,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Update failed'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _showContactCustomer(BuildContext context, String name) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contact $name'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
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
