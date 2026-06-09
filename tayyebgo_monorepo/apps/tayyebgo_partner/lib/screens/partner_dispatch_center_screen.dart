import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerDispatchCenterScreen extends StatelessWidget {
  const PartnerDispatchCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Dispatch Center', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(context, 'Active Orders', '3', Icons.receipt_long_rounded, context.warningColor),
          const SizedBox(height: 12),
          _statusCard(context, 'Pending Acceptance', '1', Icons.hourglass_top_rounded, context.errorColor),
          const SizedBox(height: 12),
          _statusCard(context, 'Ready for Pickup', '2', Icons.inventory_2_rounded, context.successColor),
          const SizedBox(height: 24),
          Text('Recent Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          _orderCard(context, '#1042', 'Ahmad K.', '2 items', 'SYP 4,500', 'New', context.errorColor),
          const SizedBox(height: 10),
          _orderCard(context, '#1041', 'Sara M.', '1 item', 'SYP 2,800', 'Prep', context.warningColor),
          const SizedBox(height: 10),
          _orderCard(context, '#1040', 'Omar H.', '3 items', 'SYP 6,200', 'Ready', context.successColor),
          const SizedBox(height: 10),
          _orderCard(context, '#1039', 'Lina A.', '1 item', 'SYP 1,900', 'Delivered', context.textMutedColor),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context, String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
          const Spacer(),
          Text(count, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: color)),
        ],
      ),
    );
  }

  Widget _orderCard(BuildContext context, String id, String customer, String items, String total, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(id, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
              const SizedBox(height: 2),
              Text('$customer · $items', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(total, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
