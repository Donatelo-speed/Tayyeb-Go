import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_design.dart';

class FinanceSection extends StatefulWidget {
  const FinanceSection({super.key});
  @override
  State<FinanceSection> createState() => _FinanceSectionState();
}

class _FinanceSectionState extends State<FinanceSection> {
  double _revenue = 0, _commissions = 0, _refunds = 0, _settled = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ordersSnap = await FirebaseFirestore.instance.collection('orders').get();
    final settlementsSnap = await FirebaseFirestore.instance.collection('settlements').get();
    if (!mounted) return;
    double r = 0, rf = 0;
    for (final d in ordersSnap.docs) {
      final data = d.data();
      r += (data['totalAmount'] as num?)?.toDouble() ?? 0;
      if (data['status'] == 'cancelled') rf += (data['totalAmount'] as num?)?.toDouble() ?? 0;
    }
    double s = 0;
    for (final d in settlementsSnap.docs) { s += ((d.data() as Map)['amount'] as num?)?.toDouble() ?? 0; }
    setState(() { _revenue = r; _refunds = rf; _commissions = r * 0.15; _settled = s; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Finance & Revenue', style: isDark ? AdminTypography.h2(true) : AdminTypography.h2(false)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _FinCard(isDark: isDark, label: 'Total Revenue', value: '\$${_revenue.toStringAsFixed(0)}', icon: Icons.attach_money_rounded, color: AdminColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _FinCard(isDark: isDark, label: 'Commissions (15%)', value: '\$${_commissions.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, color: AdminColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _FinCard(isDark: isDark, label: 'Refunds', value: '\$${_refunds.toStringAsFixed(0)}', icon: Icons.money_off_rounded, color: AdminColors.danger)),
          const SizedBox(width: 12),
          Expanded(child: _FinCard(isDark: isDark, label: 'Total Settled', value: '\$${_settled.toStringAsFixed(0)}', icon: Icons.check_circle_rounded, color: AdminColors.secondary)),
        ]),
        const SizedBox(height: 32),
        Text('Restaurant Commission Debts', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return Column(children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final debt = (d['commissionDebt'] as num?)?.toDouble() ?? 0;
              final ceiling = (d['commissionCeiling'] as num?)?.toDouble() ?? 50000;
              final ratio = ceiling > 0 ? (debt / ceiling).clamp(0.0, 1.0) : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Text(d['name'] as String? ?? 'N/A', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false))),
                    Text('${debt.toStringAsFixed(0)} / ${ceiling.toStringAsFixed(0)} SYP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ratio > 0.85 ? AdminColors.danger : ratio > 0.6 ? AdminColors.warning : isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: isDark ? AdminColors.bgDarkSurface : AdminColors.bgLightSurface, color: ratio > 0.85 ? AdminColors.danger : ratio > 0.6 ? AdminColors.warning : AdminColors.success)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton.icon(onPressed: () => _settle(doc.id, d['name'] ?? ''), icon: const Icon(Icons.paid_rounded, size: 16), label: const Text('Settle'), style: TextButton.styleFrom(foregroundColor: AdminColors.primary)),
                    TextButton.icon(onPressed: () => _adjustCeiling(doc.id, d['name'] ?? '', ceiling), icon: const Icon(Icons.tune_rounded, size: 16), label: const Text('Ceiling'), style: TextButton.styleFrom(foregroundColor: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary)),
                  ]),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    );
  }

  Future<void> _settle(String id, String name) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xl)), title: Text('Settle $name'), content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (SYP)')), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary), child: const Text('Settle')),
    ]));
    if (ok == true && mounted) {
      final amt = double.tryParse(ctrl.text) ?? 0;
      if (amt > 0) { await FirebaseFirestore.instance.collection('settlements').add({'restaurantId': id, 'restaurantName': name, 'amount': amt, 'timestamp': FieldValue.serverTimestamp()}); }
    }
    ctrl.dispose();
  }

  Future<void> _adjustCeiling(String id, String name, double current) async {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xl)), title: Text('Ceiling for $name'), content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New ceiling (SYP)')), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary), child: const Text('Update')),
    ]));
    if (ok == true && mounted) {
      final v = double.tryParse(ctrl.text) ?? 50000;
      await FirebaseFirestore.instance.collection('restaurants').doc(id).update({'commissionCeiling': v});
    }
    ctrl.dispose();
  }
}

class _FinCard extends StatelessWidget {
  final bool isDark;
  final String label, value;
  final IconData icon;
  final Color color;
  const _FinCard({required this.isDark, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AdminRadius.md)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 16),
        Text(value, style: isDark ? AdminTypography.kpiValue(true) : AdminTypography.kpiValue(false)),
        const SizedBox(height: 4),
        Text(label, style: isDark ? AdminTypography.kpiLabel(true) : AdminTypography.kpiLabel(false)),
      ]),
    );
  }
}