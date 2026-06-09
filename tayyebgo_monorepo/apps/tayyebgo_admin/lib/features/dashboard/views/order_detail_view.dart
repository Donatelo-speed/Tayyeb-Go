import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class OrderDetailView extends StatelessWidget {
  final String orderId;
  const OrderDetailView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
            if (!snap.hasData || !snap.data!.exists) return Center(child: Text('Order not found', style: GoogleFonts.inter(color: context.textMutedColor)));
            final d = snap.data!.data() as Map<String, dynamic>;
            return _buildDetail(context, d);
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'pending';
    final totalAmount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
    final deliveryFee = (d['deliveryFee'] as num?)?.toDouble() ?? 0;
    final tax = (d['tax'] as num?)?.toDouble() ?? 0;
    final customerName = d['customerName'] as String? ?? 'Unknown';
    final customerPhone = d['customerPhone'] as String? ?? '—';
    final restaurantName = d['restaurantName'] as String? ?? 'Unknown';
    final restaurantId = d['restaurantId'] as String? ?? '';
    final driverName = d['driverName'] as String? ?? 'Unassigned';
    final paymentMethod = d['paymentMethod'] as String? ?? 'unknown';
    final deliveryAddress = d['deliveryAddress'] as String? ?? '—';
    final items = List<Map<String, dynamic>>.from(d['items'] ?? []);
    final statusHistory = List<Map<String, dynamic>>.from(d['statusHistory'] ?? []);
    final createdAt = d['createdAt'] as Timestamp?;
    final statusColor = _statusColor(context, status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status[0].toUpperCase() + status.substring(1), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor)),
                ),
                const Spacer(),
                Text('\$${totalAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: context.textPrimaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(context, 'Customer', Icons.person_rounded, [
            _infoRow(context, 'Name', customerName),
            _infoRow(context, 'Phone', customerPhone),
          ]),
          const SizedBox(height: 10),
          _infoCard(context, 'Store', Icons.store_rounded, [
            _infoRow(context, 'Name', restaurantName),
            _infoRow(context, 'ID', restaurantId.isNotEmpty ? '#${restaurantId.substring(0, restaurantId.length > 8 ? 8 : restaurantId.length)}' : '—'),
          ]),
          const SizedBox(height: 10),
          _infoCard(context, 'Driver', Icons.delivery_dining_rounded, [
            _infoRow(context, 'Name', driverName),
          ]),
          const SizedBox(height: 10),
          _infoCard(context, 'Payment', Icons.payment_rounded, [
            _infoRow(context, 'Method', paymentMethod.toUpperCase()),
            _infoRow(context, 'Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
            _infoRow(context, 'Tax', '\$${tax.toStringAsFixed(2)}'),
          ]),
          if (deliveryAddress != '—') ...[
            const SizedBox(height: 10),
            _infoCard(context, 'Delivery Address', Icons.location_on_rounded, [
              _infoRow(context, 'Address', deliveryAddress),
            ]),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Items', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            const SizedBox(height: 10),
            ...items.map((item) => _itemRow(context, item)),
          ],
          if (statusHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Status History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            const SizedBox(height: 10),
            ...statusHistory.map((h) => _historyRow(context, h)),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 10),
            _infoCard(context, 'Timeline', Icons.schedule_rounded, [
              _infoRow(context, 'Created', _formatDateTime(createdAt.toDate())),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, String title, IconData icon, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.primaryColor),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimaryColor))),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'Item';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Text('x$qty', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: context.primaryColor)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor))),
          Text('\$${(price * qty).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _historyRow(BuildContext context, Map<String, dynamic> h) {
    final from = h['from'] as String? ?? '';
    final to = h['to'] as String? ?? '';
    final timestamp = h['timestamp'];
    final actorId = h['actorId'] as String? ?? '';
    String timeText = '';
    if (timestamp is Timestamp) {
      timeText = _formatDateTime(timestamp.toDate());
    } else if (timestamp is String) {
      timeText = timestamp;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_forward_rounded, size: 14, color: context.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              from.isNotEmpty ? '$from → $to' : to,
              style: GoogleFonts.inter(fontSize: 12, color: context.textPrimaryColor),
            ),
          ),
          if (actorId.isNotEmpty) ...[
            Text(actorId, style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
            const SizedBox(width: 6),
          ],
          if (timeText.isNotEmpty) Text(timeText, style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'pending': return context.warningColor;
      case 'accepted': return context.primaryColor;
      case 'preparing': return context.primaryColor;
      case 'enRoute': return context.primaryColor;
      case 'delivered': return context.successColor;
      case 'cancelled': return context.errorColor;
      case 'refunded': return context.primaryColor;
      default: return context.textMutedColor;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
