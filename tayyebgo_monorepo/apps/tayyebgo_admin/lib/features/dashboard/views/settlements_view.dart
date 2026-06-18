import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

const _purple = Color(0xFF8B5CF6);

class SettlementsView extends StatelessWidget {
  const SettlementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Driver Settlements', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').where('isActive', isEqualTo: true).limit(200).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: context.primaryColor));
            }
            if (snap.hasError) {
              return Center(child: Text('Error loading drivers', style: GoogleFonts.inter(color: context.textMutedColor)));
            }
            final drivers = snap.data?.docs ?? [];
            if (drivers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: context.borderColor),
                    const SizedBox(height: 12),
                    Text('No active drivers', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummary(context, drivers),
                const SizedBox(height: 20),
                ...drivers.map((d) => _driverRow(context, d)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, List<QueryDocumentSnapshot> drivers) {
    int total = drivers.length;
    int active = drivers.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['isOnline'] == true;
    }).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 500 ? 1 : constraints.maxWidth < 900 ? 2 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            _summaryCard(context, Icons.people_rounded, 'Total Drivers', '$total', context.primaryColor),
            _summaryCard(context, Icons.circle_rounded, 'Online Now', '$active', context.successColor),
            _summaryCard(context, Icons.payments_rounded, 'Cash Pool', '—', context.warningColor, subtitle: 'Tap driver to view'),
            _summaryCard(context, Icons.receipt_long_rounded, 'Open Invoices', '—', _purple, subtitle: 'Tap driver to view'),
          ],
        );
      },
    );
  }

  Widget _summaryCard(BuildContext context, IconData icon, String label, String value, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.brMd),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
                if (subtitle != null) Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverRow(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['displayName'] as String? ?? d['name'] as String? ?? 'Driver';
    final phone = d['phone'] as String? ?? '—';
    final isOnline = d['isOnline'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Center(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.primaryColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: isOnline ? context.successColor : context.textMutedColor, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(phone, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showSettlement(context, d, doc.id),
            icon: Icon(Icons.receipt_long_rounded, size: 16, color: context.primaryColor),
            label: Text('Settle', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSettlement(BuildContext context, Map<String, dynamic> driver, String driverId) {
    final name = driver['displayName'] as String? ?? driver['name'] as String? ?? 'Driver';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('driverId', isEqualTo: driverId)
              .where('status', isEqualTo: 'delivered')
              .where('paymentMethod', isEqualTo: 'cash')
              .limit(500)
              .orderBy('deliveredAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            double collected = 0;
            double platformShare = 0;
            double driverShare = 0;
            int count = 0;
            if (snap.hasData) {
              for (final doc in snap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final amt = (d['totalAmount'] as num?)?.toDouble() ?? 0;
                collected += amt;
                count++;
              }
              platformShare = collected * 0.15;
              driverShare = collected - platformShare;
            }
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: AppRadius.brSm)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.brLg,
                      ),
                      child: Center(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: context.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                          Text('Cash settlement', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [context.primaryColor, context.primaryColor]),
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash Collected', style: GoogleFonts.inter(color: context.textPrimaryColor.withValues(alpha: 0.85), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${collected.toStringAsFixed(0)} SYP', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('$count cash orders', style: GoogleFonts.inter(color: context.textPrimaryColor.withValues(alpha: 0.85), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _settlementRow(context, 'Platform share (15%)', '${platformShare.toStringAsFixed(0)} SYP', context.textPrimaryColor),
                _settlementRow(context, 'Driver share (85%)', '${driverShare.toStringAsFixed(0)} SYP', context.textPrimaryColor),
                Divider(height: 24, color: context.borderColor),
                _settlementRow(context, 'Owes platform', '${platformShare.toStringAsFixed(0)} SYP', context.errorColor, bold: true),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.borderColor),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                        ),
                        child: Text('Close', style: GoogleFonts.inter(color: context.textMutedColor)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('settlements').add({
                            'driverId': driverId,
                            'driverName': name,
                            'collected': collected,
                            'platformShare': platformShare,
                            'driverShare': driverShare,
                            'orderCount': count,
                            'status': 'paid',
                            'settledAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Settlement recorded', style: GoogleFonts.inter()), backgroundColor: context.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text('Mark Paid', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(backgroundColor: context.successColor, foregroundColor: context.textPrimaryColor, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _settlementRow(BuildContext context, String label, String value, Color valueColor, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor))),
          Text(value, style: GoogleFonts.inter(fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
