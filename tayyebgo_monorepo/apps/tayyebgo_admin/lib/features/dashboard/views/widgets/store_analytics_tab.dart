import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../shared.dart';

class StoreAnalyticsTab extends StatelessWidget {
  final String storeId;
  const StoreAnalyticsTab({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirestoreService.instance.watchOrdersRaw(filter: OrderFilter(storeId: storeId), limit: 200),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const ShimmerLoading(itemCount: 3);
        }
        final orders = snap.data ?? const [];
        final totalRevenue = orders.fold<double>(0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
        final completed = orders.where((o) => o['status'] == 'delivered').length;
        final cancelled = orders.where((o) => o['status'] == 'cancelled').length;
        final avgOrder = orders.isEmpty ? 0.0 : totalRevenue / orders.length;
        return Column(children: [
          Row(children: [
            Expanded(child: _AnalyticsStatTile(context, 'Total Revenue', '\$${totalRevenue.toStringAsFixed(0)}', Icons.attach_money, context.successColor)),
            const SizedBox(width: 12),
            Expanded(child: _AnalyticsStatTile(context, 'Total Orders', '${orders.length}', Icons.receipt_long, context.primaryColor)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _AnalyticsStatTile(context, 'Completed', '$completed', Icons.check_circle, context.successColor)),
            const SizedBox(width: 12),
            Expanded(child: _AnalyticsStatTile(context, 'Cancelled', '$cancelled', Icons.cancel, context.errorColor)),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: _AnalyticsStatTile(context, 'Average Order Value', '\$${avgOrder.toStringAsFixed(2)}', Icons.trending_up, context.warningColor)),
        ]);
      },
    );
  }
}

Widget _AnalyticsStatTile(BuildContext context, String label, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: cardDecoBordered(context),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
      ]),
    ]),
  );
}
