import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'order_detail_view.dart';
import 'shared.dart';

const _purple = Color(0xFF8B5CF6);

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

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'pending': return context.warningColor;
      case 'accepted': return context.primaryColor;
      case 'preparing': return context.primaryColor;
      case 'enRoute': return context.primaryColor;
      case 'delivered': return context.successColor;
      case 'cancelled': return context.errorColor;
      case 'refunded': return _purple;
      default: return context.textMutedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).limit(500).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: context.primaryColor));
            }
            if (snap.hasError) {
              return Center(child: Text('Error loading orders', style: GoogleFonts.inter(color: context.textMutedColor)));
            }
            var docs = snap.data?.docs ?? [];
            if (_statusFilter != 'all') {
              docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == _statusFilter).toList();
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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: AppRadius.brMd,
                            border: Border.all(color: context.borderColor),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 13),
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.textMutedColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _filterChip(context, 'All', 'all'),
                      const SizedBox(width: 6),
                      _filterChip(context, 'Active', 'pending'),
                      const SizedBox(width: 6),
                      _filterChip(context, 'Delivered', 'delivered'),
                      const SizedBox(width: 6),
                      _filterChip(context, 'Cancelled', 'cancelled'),
                      const SizedBox(width: 6),
                      _filterChip(context, 'Refunded', 'refunded'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${docs.length} orders', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: docs.isEmpty
                      ? Center(
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
                              Text('No orders found', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailView(orderId: docs[i].id))),
                            child: _OrderRow(doc: docs[i], statusColor: (s) => _statusColor(context, s)),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : context.surfaceColor,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: selected ? context.primaryColor : context.borderColor),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : context.textSecondaryColor)),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Color Function(String) statusColor;

  const _OrderRow({required this.doc, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final customerName = d['customerName'] as String? ?? 'Unknown';
    final storeName = d['restaurantName'] as String? ?? 'Unknown';
    final status = d['status'] as String? ?? 'pending';
    final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
    final paymentMethod = d['paymentMethod'] as String? ?? 'unknown';
    final statusLabel = status[0].toUpperCase() + status.substring(1);
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${id.substring(0, id.length > 8 ? 8 : id.length)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(storeName, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customerName, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brSm,
            ),
            child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimaryColor)),
              Text(paymentMethod, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 16, color: context.textMutedColor),
            onSelected: (v) {
              if (v == 'refund') _refundOrder(context, id, amount);
              if (v == 'contact') ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contact $customerName', style: GoogleFonts.inter()), backgroundColor: context.primaryColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)));
            },
            itemBuilder: (_) => [
              if (status == 'delivered')
                PopupMenuItem(value: 'refund', child: Text('Refund', style: GoogleFonts.inter(fontSize: 13, color: context.warningColor))),
              PopupMenuItem(value: 'contact', child: Text('Contact Customer', style: GoogleFonts.inter(fontSize: 13))),
            ],
          ),
        ],
      ),
    );
  }

  void _refundOrder(BuildContext context, String orderId, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
        title: Text('Refund Order', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: Text('Process refund of \$${amount.toStringAsFixed(2)}?', style: GoogleFonts.inter(color: context.textSecondaryColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: context.textSecondaryColor))),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.runTransaction((txn) async {
                  final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
                  final snap = await txn.get(orderRef);
                  if (!snap.exists) throw Exception('Order not found');
                  final data = snap.data()!;
                  final history = List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
                  history.add({'from': data['status'], 'to': 'refunded', 'timestamp': FieldValue.serverTimestamp(), 'actorId': 'admin'});
                  txn.update(orderRef, {'status': 'refunded', 'refundedAt': FieldValue.serverTimestamp(), 'refundedAmount': amount, 'statusHistory': history});
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refund processed', style: GoogleFonts.inter()), backgroundColor: context.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: GoogleFonts.inter()), backgroundColor: context.errorColor));
                }
              }
            },
            child: Text('Process Refund', style: GoogleFonts.inter(color: context.primaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
