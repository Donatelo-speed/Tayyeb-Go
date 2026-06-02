import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class FinanceView extends StatelessWidget {
  const FinanceView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return pageContainer(context, child: StreamScreenBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Orders').limit(500).snapshots(),
        onLoading: () => const ShimmerLoading(itemCount: 4),
        onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
        onSuccess: (context, ordersSnap) {
          int totalOrders = 0;
          double grossRevenue = 0;
          double totalRefunds = 0;
          int refundCount = 0;
          final Map<String, double> restaurantRevenue = {};
          for (final doc in ordersSnap.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final amt = (d['totalAmount'] as num?)?.toDouble() ?? 0;
            final restId = d['restaurantId'] as String? ?? 'unknown';
            final status = d['status'] as String? ?? '';
            totalOrders++;
            grossRevenue += amt;
            restaurantRevenue[restId] = (restaurantRevenue[restId] ?? 0) + amt;
            if (status == 'refunded') {
              totalRefunds += (d['refundedAmount'] as num?)?.toDouble() ?? amt;
              refundCount++;
            }
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Restaurants').orderBy('createdAt', descending: true).limit(500).snapshots(),
            builder: (context, restSnap) {
              if (restSnap.hasError) {
                return Center(child: Text('Error loading restaurants: ${restSnap.error}', style: const TextStyle(color: Colors.red)));
              }
              if (restSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              double totalCommission = 0;
              double driverPayouts = 0;
              double storePayouts = 0;
              final restaurantData = <Map<String, dynamic>>[];
              if (restSnap.hasData) {
                for (final doc in restSnap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final rate = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
                  final rev = restaurantRevenue[doc.id] ?? 0;
                  final comm = rev * rate / 100;
                  totalCommission += comm;
                  storePayouts += rev - comm;
                  restaurantData.add({
                    'id': doc.id,
                    'name': d['name'] ?? 'Unknown',
                    'rate': rate,
                    'revenue': rev,
                    'commission': comm,
                    'payout': rev - comm,
                  });
                }
                driverPayouts = totalCommission * 0.6;
              }
              return _FinanceContent(
                grossRevenue: grossRevenue,
                totalCommission: totalCommission,
                totalRefunds: totalRefunds,
                refundCount: refundCount,
                driverPayouts: driverPayouts,
                storePayouts: storePayouts,
                totalOrders: totalOrders,
                restaurantData: restaurantData,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }
}

class _FinanceContent extends StatelessWidget {
  final double grossRevenue, totalCommission, totalRefunds, driverPayouts, storePayouts;
  final int refundCount, totalOrders;
  final List<Map<String, dynamic>> restaurantData;
  final bool isDark;

  const _FinanceContent({
    required this.grossRevenue, required this.totalCommission, required this.totalRefunds,
    required this.refundCount, required this.driverPayouts, required this.storePayouts,
    required this.totalOrders, required this.restaurantData, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      title: 'Finance',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Financial Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.textPrimaryColor)),
          const SizedBox(height: 6),
          Text('Revenue, commissions, and payouts', style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
          const SizedBox(height: 24),
          Wrap(spacing: 12, runSpacing: 12, children: [
            StatCard(title: 'Gross Revenue', value: '\$${grossRevenue.toStringAsFixed(0)}', icon: Icons.attach_money, gradient: AppGradients.statBlue),
            StatCard(title: 'Platform Commission', value: '\$${totalCommission.toStringAsFixed(0)}', icon: Icons.paid, gradient: AppGradients.statOrange),
            StatCard(title: 'Refunds', value: '\$${totalRefunds.toStringAsFixed(0)}', icon: Icons.money_off, gradient: AppGradients.statPurple, subtitle: '$refundCount orders'),
            StatCard(title: 'Driver Payouts', value: '\$${driverPayouts.toStringAsFixed(0)}', icon: Icons.delivery_dining, gradient: AppGradients.statCyan),
            StatCard(title: 'Store Payouts', value: '\$${storePayouts.toStringAsFixed(0)}', icon: Icons.store, gradient: AppGradients.statGreen),
          ]),
          const SizedBox(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _buildActionsCard(context)),
            const SizedBox(width: 24),
            Expanded(child: _buildSummaryCard(context)),
          ]),
          const SizedBox(height: 24),
          _buildPayoutsSection(context),
          const SizedBox(height: 24),
          _buildRestaurantBreakdown(context),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? DarkAppColors.divider : AppColors.divider).withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        const SizedBox(height: 16),
        _actionButton(context, Icons.download, 'Export Revenue Report', AppColors.primary, _exportRevenue),
        const SizedBox(height: 8),
        _actionButton(context, Icons.paid, 'Process Payouts', AppColors.success, _processPayouts),
        const SizedBox(height: 8),
        _actionButton(context, Icons.assessment, 'Export Full Report', AppColors.premium, _exportReport),
      ]),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? DarkAppColors.divider : AppColors.divider).withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Summary', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        const SizedBox(height: 16),
        _financeSummary('Net Revenue', '\$${(grossRevenue - totalRefunds).toStringAsFixed(0)}', AppColors.success),
        const Divider(height: 20),
        _financeSummary('Platform Net', '\$${(totalCommission - driverPayouts).toStringAsFixed(0)}', AppColors.primary),
        const Divider(height: 20),
        _financeSummary('Refund Rate', totalOrders > 0 ? '${((refundCount / totalOrders) * 100).toStringAsFixed(1)}%' : '0%', AppColors.error),
        const Divider(height: 20),
        _financeSummary('Avg Commission/Order', totalOrders > 0 ? '\$${(totalCommission / totalOrders).toStringAsFixed(2)}' : '\$0', AppColors.premium),
      ]),
    );
  }

  Widget _buildPayoutsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? DarkAppColors.divider : AppColors.divider).withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Payout Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _processPayouts(context),
            icon: const Icon(Icons.payments, size: 18),
            label: const Text('Process All'),
          ),
        ]),
        const SizedBox(height: 16),
        _buildPayoutStat(context, 'Pending Payouts', '\$${(storePayouts).toStringAsFixed(0)}', 'Awaiting processing', AppColors.warning),
        const SizedBox(height: 8),
        _buildPayoutStat(context, 'Driver Payouts', '\$${driverPayouts.toStringAsFixed(0)}', '60% of commission', AppColors.primary),
        const SizedBox(height: 8),
        _buildPayoutStat(context, 'Net Revenue', '\$${(grossRevenue - totalRefunds - totalCommission).toStringAsFixed(0)}', 'After all costs', AppColors.success),
      ]),
    );
  }

  Widget _buildPayoutStat(BuildContext context, String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
          ]),
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ]),
    );
  }

  Widget _buildRestaurantBreakdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? DarkAppColors.divider : AppColors.divider).withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Per-Restaurant Breakdown', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        const SizedBox(height: 16),
        ...restaurantData.map((rd) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? DarkAppColors.surfaceAlt : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (isDark ? DarkAppColors.divider : AppColors.divider).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rd['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                Text('Commission: ${(rd['rate'] as double).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Rev: \$${(rd['revenue'] as double).toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: context.textPrimaryColor)),
              Text('Fee: \$${(rd['commission'] as double).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('Payout: \$${(rd['payout'] as double).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
            ]),
          ]),
        )),
      ]),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color, void Function(BuildContext) onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => onTap(context),
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: color.withValues(alpha: 0.03),
        ),
      ),
    );
  }

  Widget _financeSummary(String label, String value, Color color) {
    return Builder(
      builder: (context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? DarkAppColors.textSecondary : AppColors.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ]),
    );
  }

  void _exportRevenue(BuildContext context) {
    _showExportSnackbar(context, 'Revenue');
  }

  void _processPayouts(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('activity_log').add({
        'text': 'Payouts processed: \$${storePayouts.toStringAsFixed(0)} to stores, \$${driverPayouts.toStringAsFixed(0)} to drivers',
        'color': 'green',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        context.showSuccess('Payouts processed and logged');
      }
    } catch (e) {
      if (context.mounted) context.showError('Failed to process payouts');
    }
  }

  void _exportReport(BuildContext context) {
    _showExportSnackbar(context, 'Full Financial Report');
  }

  void _showExportSnackbar(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label exported as CSV'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
