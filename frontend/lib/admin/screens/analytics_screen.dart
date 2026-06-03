import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double _revenue = 0;
  int _orders = 0, _stores = 0, _drivers = 0, _customers = 0;
  late StreamSubscription _orderSub, _storeSub, _driverSub, _userSub;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _orderSub = db.collection('orders').snapshots().listen((s) {
      double rev = 0;
      for (final d in s.docs) { rev += (d.data()['totalAmount'] as num?)?.toDouble() ?? 0; }
      if (mounted) setState(() { _revenue = rev; _orders = s.docs.length; });
    });
    _storeSub = db.collection('restaurants').snapshots().listen((s) => mounted ? setState(() => _stores = s.docs.length) : null);
    _driverSub = db.collection('drivers').snapshots().listen((s) => mounted ? setState(() => _drivers = s.docs.length) : null);
    _userSub = db.collection('users').snapshots().listen((s) => mounted ? setState(() => _customers = s.docs.length) : null);
  }

  @override
  void dispose() { _orderSub.cancel(); _storeSub.cancel(); _driverSub.cancel(); _userSub.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analytics', style: AdminTypography.h1(isDark)),
        const SizedBox(height: AdminSpacing.xxl),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: AdminSpacing.md, mainAxisSpacing: AdminSpacing.md, childAspectRatio: 1.3),
          children: [
            AdminKpiCard(label: 'Total Revenue', value: '\$${_revenue.toStringAsFixed(0)}', icon: Icons.attach_money_rounded, color: AdminColors.success),
            AdminKpiCard(label: 'Total Orders', value: '$_orders', icon: Icons.receipt_long_rounded, color: AdminColors.info),
            AdminKpiCard(label: 'Active Stores', value: '$_stores', icon: Icons.store_rounded, color: AdminColors.primary),
            AdminKpiCard(label: 'Total Drivers', value: '$_drivers', icon: Icons.delivery_dining_rounded, color: const Color(0xFF0891B2)),
            AdminKpiCard(label: 'Total Customers', value: '$_customers', icon: Icons.group_rounded, color: const Color(0xFF7C3AED)),
          ],
        ),
        const SizedBox(height: AdminSpacing.xxxl),
        Text('Top Performing Stores', style: AdminTypography.h2(isDark)),
        const SizedBox(height: AdminSpacing.lg),
        _TopStoresList(isDark: isDark),
        const SizedBox(height: AdminSpacing.xxxl),
        Text('Revenue Trends', style: AdminTypography.h2(isDark)),
        const SizedBox(height: AdminSpacing.lg),
        Container(
          height: 300,
          padding: const EdgeInsets.all(AdminSpacing.xl),
          decoration: cardDecoration(isDark),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.show_chart_rounded, size: 48, color: AdminColors.textMuted(isDark)),
              const SizedBox(height: AdminSpacing.lg),
              Text('Revenue chart will render here', style: AdminTypography.bodySmall(isDark)),
              Text('Connect to Firestore analytics for live data', style: AdminTypography.caption(isDark)),
            ]),
          ),
        ),
        const SizedBox(height: AdminSpacing.xxxl),
        Text('Zone Heatmap', style: AdminTypography.h2(isDark)),
        const SizedBox(height: AdminSpacing.lg),
        Container(
          height: 350,
          padding: const EdgeInsets.all(AdminSpacing.xl),
          decoration: cardDecoration(isDark),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.map_rounded, size: 48, color: AdminColors.textMuted(isDark)),
              const SizedBox(height: AdminSpacing.lg),
              Text('Homs delivery zone heatmap', style: AdminTypography.bodySmall(isDark)),
              Text('Integration with Google Maps ready', style: AdminTypography.caption(isDark)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TopStoresList extends StatelessWidget {
  final bool isDark;
  const _TopStoresList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').orderBy('totalOrders', descending: true).limit(5).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const AdminLoadingState(itemCount: 5, itemHeight: 56);
        return Column(
          children: snap.data!.docs.asMap().entries.map((e) {
            final d = e.value.data() as Map<String, dynamic>;
            final rank = e.key + 1;
            final name = d['name'] ?? 'Unnamed';
            final orders = d['totalOrders'] ?? d['orderCount'] ?? 0;
            final revenue = (d['revenue'] as num?)?.toDouble() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg, vertical: AdminSpacing.md),
              decoration: cardDecoration(isDark),
              child: Row(children: [
                SizedBox(width: 32, child: Text('#$rank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: rank <= 3 ? AdminColors.primary : AdminColors.textMuted(isDark)))),
                const SizedBox(width: AdminSpacing.md),
                Expanded(child: Text(name, style: AdminTypography.h4(isDark))),
                Text('$orders orders', style: AdminTypography.bodySmall(isDark)),
                const SizedBox(width: AdminSpacing.xl),
                SizedBox(width: 100, child: Text('\$${revenue.toStringAsFixed(0)}', style: AdminTypography.mono(isDark), textAlign: TextAlign.end)),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}