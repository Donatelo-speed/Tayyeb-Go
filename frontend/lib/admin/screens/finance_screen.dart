import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  double _totalRevenue = 0;
  double _commissions = 0;
  double _refunds = 0;
  double _settled = 0;
  final double _driverPayouts = 0;
  late StreamSubscription _orderSub, _storesSub;

  @override
  void initState() {
    super.initState();
    _orderSub = FirebaseFirestore.instance.collection('orders').snapshots().listen((s) {
      double rev = 0, ref = 0, comm = 0;
      for (final d in s.docs) {
        final data = d.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        rev += amount;
        if (data['status'] == 'cancelled') ref += amount;
        comm += amount * 0.15;
      }
      if (mounted) setState(() { _totalRevenue = rev; _refunds = ref; _commissions = comm; });
    });
    _storesSub = FirebaseFirestore.instance.collection('restaurants').snapshots().listen((s) {
      double settled = 0;
      for (final d in s.docs) {
        final data = d.data();
        settled += (data['commissionDebt'] as num?)?.toDouble() ?? 0;
      }
      if (mounted) setState(() => _settled = settled);
    });
  }

  @override
  void dispose() { _orderSub.cancel(); _storesSub.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final netRevenue = _totalRevenue - _refunds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Finance Overview', style: AdminTypography.h1(isDark)),
        const SizedBox(height: AdminSpacing.xxl),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: AdminSpacing.md, mainAxisSpacing: AdminSpacing.md, childAspectRatio: 1.5),
          children: [
            AdminKpiCard(label: 'Total Revenue', value: '\$${_totalRevenue.toStringAsFixed(0)}', icon: Icons.attach_money_rounded, color: AdminColors.success),
            AdminKpiCard(label: 'Net Revenue', value: '\$${netRevenue.toStringAsFixed(0)}', icon: Icons.trending_up_rounded, color: AdminColors.primary),
            AdminKpiCard(label: 'Commissions (15%)', value: '\$${_commissions.toStringAsFixed(0)}', icon: Icons.percent_rounded, color: AdminColors.info),
            AdminKpiCard(label: 'Refunds', value: '\$${_refunds.toStringAsFixed(0)}', icon: Icons.replay_rounded, color: AdminColors.danger),
            AdminKpiCard(label: 'Settled', value: '\$${_settled.toStringAsFixed(0)}', icon: Icons.check_circle_rounded, color: AdminColors.success),
            AdminKpiCard(label: 'Driver Payouts', value: '\$${_driverPayouts.toStringAsFixed(0)}', icon: Icons.payments_rounded, color: AdminColors.warning),
          ],
        ),
        const SizedBox(height: AdminSpacing.xxxl),
        Text('Store Commission Debt', style: AdminTypography.h2(isDark)),
        const SizedBox(height: AdminSpacing.lg),
        _StoreCommissionList(isDark: isDark),
        const SizedBox(height: AdminSpacing.xxxl),
        Row(children: [
          Expanded(child: _ExportButton(isDark: isDark, label: 'Export PDF', icon: Icons.picture_as_pdf_rounded)),
          const SizedBox(width: AdminSpacing.md),
          Expanded(child: _ExportButton(isDark: isDark, label: 'Export Excel', icon: Icons.table_chart_rounded)),
        ]),
      ]),
    );
  }
}

class _StoreCommissionList extends StatelessWidget {
  final bool isDark;
  const _StoreCommissionList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const AdminLoadingState(itemCount: 3, itemHeight: 64);
        final docs = snap.data!.docs;
        return Column(children: docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final debt = (d['commissionDebt'] as num?)?.toDouble() ?? 0;
          final ceiling = (d['commissionCeiling'] as num?)?.toDouble() ?? 50000;
          final pct = ceiling > 0 ? (debt / ceiling).clamp(0.0, 1.0) : 0.0;
          final color = pct > 0.8 ? AdminColors.danger : pct > 0.5 ? AdminColors.warning : AdminColors.success;

          return Container(
            margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
            padding: const EdgeInsets.all(AdminSpacing.lg),
            decoration: cardDecoration(isDark),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['name'] ?? 'Unnamed', style: AdminTypography.h4(isDark)),
                const SizedBox(height: 4),
                Text('\$${debt.toStringAsFixed(0)} / \$${ceiling.toStringAsFixed(0)}', style: AdminTypography.bodySmall(isDark)),
              ])),
              const SizedBox(width: AdminSpacing.lg),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(AdminRadius.full),
                child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AdminColors.surface(isDark), color: color),
              )),
              const SizedBox(width: AdminSpacing.lg),
              TextButton(onPressed: () {}, child: const Text('Settle')),
            ]),
          );
        }).toList());
      },
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool isDark;
  final String label;
  final IconData icon;
  const _ExportButton({required this.isDark, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
    );
  }
}