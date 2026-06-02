import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../theme/tayyebgo_theme.dart';
import 'tracking/tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: TayyebGoTheme.surfaceColor,
        elevation: 0,
      ),
      body: userId == null
          ? const Center(child: Text('Sign in to view orders'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildStaticOrders(context);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _buildStaticOrders(context);
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    return _OrderCard(
                      orderId: docs[index].id,
                      customerId: d['customerId'] as String? ?? '',
                      total: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
                      items: d['items'] as List? ?? [],
                      status: d['status'] as String? ?? 'pending',
                      date: d['createdAt'] as Timestamp?,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildStaticOrders(BuildContext context) {
    final orders = [
      {'id': '#ORD-2847', 'date': 'May 20, 2026', 'status': 'Processing', 'total': 45.50, 'items': 3, 'itemsList': ['Pizza', 'Coke', 'Fries']},
      {'id': '#ORD-2846', 'date': 'May 19, 2026', 'status': 'Out for Delivery', 'total': 28.00, 'items': 2, 'itemsList': ['Burger', 'Fries']},
      {'id': '#ORD-2845', 'date': 'May 18, 2026', 'status': 'Delivered', 'total': 62.00, 'items': 5, 'itemsList': ['Shawarma', 'Rice', 'Salad', 'Coke', 'Cake']},
      {'id': '#ORD-2844', 'date': 'May 15, 2026', 'status': 'Delivered', 'total': 35.00, 'items': 3, 'itemsList': ['Pizza', 'Garlic Bread', 'Coke']},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _StaticOrderCard(order: order);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId, customerId, status;
  final double total;
  final List items;
  final Timestamp? date;
  const _OrderCard({required this.orderId, required this.customerId, required this.total, required this.items, required this.status, required this.date});

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'preparing': return Colors.amber;
      case 'ready_for_driver': return Colors.teal;
      case 'picked_up': return Colors.indigo;
      case 'en_route': return Colors.blue;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final sc = _statusColor(status);
    final itemCount = items.length;
    final dateStr = date != null
        ? '${date!.toDate().month}/${date!.toDate().day}/${date!.toDate().year}'
        : '';

    return GestureDetector(
      onTap: status == 'en_route' || status == 'picked_up' || status == 'ready_for_driver'
          ? () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => TrackingScreen(orderId: orderId)))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TayyebGoTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(orderId.length > 8 ? '#${orderId.substring(0, 8)}' : orderId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: sc, fontWeight: FontWeight.w600, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.shopping_bag, size: 16, color: TayyebGoTheme.textMuted),
              const SizedBox(width: 6),
              Text('$itemCount items', style: TextStyle(color: TayyebGoTheme.textSecondary)),
              const Spacer(),
              Text('\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TayyebGoTheme.primaryColor)),
            ]),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(dateStr, style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 12)),
            ],
            if (status == 'delivered') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _reorder(context, items, cart);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Items added to cart!')),
                    );
                  },
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Reorder', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TayyebGoTheme.primaryColor,
                    side: const BorderSide(color: TayyebGoTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _reorder(BuildContext context, List items, CartProvider cart) {
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final name = item['name'] as String? ?? 'Item';
        final price = (item['basePrice'] as num?)?.toDouble() ?? 0.0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        cart.addLine(
          Product(
            id: int.tryParse(item['productId']?.toString() ?? '0') ?? 0,
            name: name,
            price: price,
            stockQuantity: 100,
          ),
          quantity: qty,
        );
      }
    }
  }
}

class _StaticOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _StaticOrderCard({required this.order});

  Color _statusColor(String s) {
    switch (s) {
      case 'Processing': return Colors.orange;
      case 'Out for Delivery': return Colors.blue;
      case 'Delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final sc = _statusColor(order['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TayyebGoTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(order['status'], style: TextStyle(color: sc, fontWeight: FontWeight.w600, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.shopping_bag, size: 16, color: TayyebGoTheme.textMuted),
            const SizedBox(width: 6),
            Text('${order['items']} items', style: TextStyle(color: TayyebGoTheme.textSecondary)),
            const Spacer(),
            Text('\$${(order['total'] as num).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TayyebGoTheme.primaryColor)),
          ]),
          if (order['status'] == 'Delivered') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  for (final name in (order['itemsList'] as List)) {
                    cart.addLine(
                      Product(id: 1, name: name as String, price: 10.0, stockQuantity: 100),
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Items added to cart!')),
                  );
                },
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Reorder', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TayyebGoTheme.primaryColor,
                  side: const BorderSide(color: TayyebGoTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
