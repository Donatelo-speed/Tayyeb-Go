import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class SettlementsView extends StatelessWidget {
  const SettlementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      title: 'Driver Settlements',
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .where('status', isEqualTo: 'active')
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
          final drivers = snap.data!.docs;
          if (drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: context.textMutedColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No active drivers', style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
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
    ));
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
            _summaryCard(context, Icons.people, 'Total Drivers', '$total', AppColors.primary),
            _summaryCard(context, Icons.circle, 'Online Now', '$active', AppColors.success),
            _summaryCard(context, Icons.payments, 'Cash Pool', '—', AppColors.warning, subtitle: 'Tap driver to view'),
            _summaryCard(context, Icons.receipt_long, 'Open Invoices', '—', AppColors.info, subtitle: 'Tap driver to view'),
          ],
        );
      },
    );
  }

  Widget _summaryCard(BuildContext context, IconData icon, String label, String value, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoBordered(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimaryColor)),
                Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
                if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 10, color: context.textMutedColor)),
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
      decoration: cardDecoBordered(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.primaryColor.withValues(alpha: 0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                    const SizedBox(width: 6),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: isOnline ? AppColors.success : context.textMutedColor, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showSettlement(context, d, doc.id),
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('Settle'),
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
              .limit(200)
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
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.dividerColor, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w700, fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                          Text('Cash settlement', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash Collected', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${collected.toStringAsFixed(0)} SYP', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('$count cash orders', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _settlementRow(context, 'Platform share (15%)', '${platformShare.toStringAsFixed(0)} SYP', context.textPrimaryColor),
                _settlementRow(context, 'Driver share (85%)', '${driverShare.toStringAsFixed(0)} SYP', context.textPrimaryColor),
                const Divider(height: 24),
                _settlementRow(context, 'Owes platform', '${platformShare.toStringAsFixed(0)} SYP', AppColors.error, bold: true),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settlement recorded'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
                          }
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Paid'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
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
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: context.textSecondaryColor))),
          Text(value, style: TextStyle(fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
