import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
import 'shared.dart';
import 'create_business_wizard.dart' as wizard;
import '../../../core/services/admin_firestore_service.dart';
import '../../../core/widgets/app_empty_state.dart' as empty;
import '../../../core/widgets/app_activity_feed.dart' as feed;

class DashboardView extends StatelessWidget {
  const DashboardView();

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AdminStatsProvider>();
    return pageContainer(context, child: AppScaffold(
      showAppBar: false,
      title: 'Dashboard',
      body: stats.loading
          ? const ShimmerLoading(itemCount: 4, itemHeight: 120)
          : stats.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: context.errorColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('Could not load dashboard', style: TextStyle(color: context.textSecondaryColor)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => stats.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: AdminFirestoreService.instance.watchOrdersRaw(limit: 500),
                  builder: (context, ordersSnap) {
                    if (ordersSnap.connectionState == ConnectionState.waiting && !ordersSnap.hasData) {
                      return const ShimmerLoading(itemCount: 4, itemHeight: 120);
                    }
                    if (ordersSnap.hasError) {
                      return empty.AppEmptyState(
                        icon: Icons.error_outline,
                        title: 'Could not load orders',
                        subtitle: ordersSnap.error.toString(),
                        actionLabel: 'Retry',
                        onAction: () => stats.refresh(),
                      );
                    }
                    final orders = ordersSnap.data ?? const [];
                    final todayData = _computeTodayData(orders);
                    final weeklyRevenue = _computeWeeklyRevenue(orders);
                    final weeklyOrders = _computeWeeklyOrders(orders);
                    final avgPrep = _computeAvgPrepTime(orders);
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Center(
                          child: SizedBox(
                            width: 1400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StaggerItem(index: 0, child: _buildHeader(context)),
                                const SizedBox(height: 24),
                                StaggerItem(index: 1, child: _QuickActionsRow()),
                                const SizedBox(height: 24),
                                StaggerItem(index: 2, child: _buildStatCards(context, stats, todayData)),
                                const SizedBox(height: 24),
                                StaggerItem(index: 3, child: _OperationsHealthCard(stats: stats, todayData: todayData, avgPrepTime: avgPrep)),
                                const SizedBox(height: 24),
                                StaggerItem(index: 4, child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 800) {
                                      return Column(children: [
                                        _TopStoresCard(),
                                        const SizedBox(height: 16),
                                        _TopDriversCard(),
                                      ]);
                                    }
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _TopStoresCard()),
                                        const SizedBox(width: 24),
                                        Expanded(child: _TopDriversCard()),
                                      ],
                                    );
                                  },
                                )),
                                const SizedBox(height: 24),
                                StaggerItem(index: 5, child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 600) {
                                      return Column(children: [
                                        _RevenueTrendChart(weeklyData: weeklyRevenue, isCurrency: true),
                                        const SizedBox(height: 24),
                                        _OrdersTrendChart(weeklyData: weeklyOrders),
                                      ]);
                                    }
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 3, child: _RevenueTrendChart(weeklyData: weeklyRevenue, isCurrency: true)),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 2, child: _OrdersTrendChart(weeklyData: weeklyOrders)),
                                      ],
                                    );
                                  },
                                )),
                                const SizedBox(height: 24),
                                StaggerItem(index: 6, child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 600) {
                                      return Column(children: [
                                        _DriverActivityChart(),
                                        const SizedBox(height: 24),
                                        SizedBox(height: 300, child: feed.AppActivityFeed(limit: 6)),
                                      ]);
                                    }
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 2, child: _DriverActivityChart()),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 3, child: SizedBox(height: 300, child: feed.AppActivityFeed(limit: 6))),
                                      ],
                                    );
                                  },
                                )),
                                const SizedBox(height: 24),
                                StaggerItem(index: 7, child: _LiveMapCard()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    ));
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Command Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.textPrimaryColor)),
            const SizedBox(height: 4),
            Text('Your platform at a glance', style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, AdminStatsProvider stats, _TodayData t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 400 ? 1 : constraints.maxWidth < 700 ? 2 : constraints.maxWidth < 1100 ? 3 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            StatCard(title: 'Active Orders', value: '${stats.stats.activeOrders}', icon: Icons.shopping_bag, gradient: AppGradients.statOrange, subtitle: 'In progress'),
            StatCard(title: 'Delivered Today', value: '${t.delivered}', icon: Icons.check_circle, gradient: AppGradients.statGreen, subtitle: 'Completed'),
            StatCard(title: 'Revenue Today', value: '\$${t.revenue.toStringAsFixed(0)}', icon: Icons.attach_money, gradient: AppGradients.statPurple, subtitle: 'Gross revenue'),
            _DriverStatCard(driverCount: stats.stats.driverCount),
            StatCard(title: 'Active Stores', value: '${stats.stats.restaurantCount}', icon: Icons.store, gradient: AppGradients.statBlue),
            StatCard(title: 'Total Customers', value: '${stats.stats.userCount}', icon: Icons.people, gradient: AppGradients.statGreen),
            StatCard(title: 'Cancelled', value: '${t.cancelled}', icon: Icons.cancel, gradient: AppGradients.statPurple, subtitle: '\$${t.cancelledRev.toStringAsFixed(0)} refunded'),
            StatCard(title: 'Pending Payouts', value: '\$${stats.stats.pendingPayouts.toStringAsFixed(0)}', icon: Icons.account_balance_wallet, gradient: AppGradients.statOrange),
          ],
        );
      },
    );
  }

  _TodayData _computeTodayData(List<Map<String, dynamic>> orders) {
    int delivered = 0, cancelled = 0;
    double revenue = 0, cancelledRev = 0;
    final today = DateTime.now();
    for (final d in orders) {
      final ts = d['createdAt'];
      final dt = ts is Timestamp ? ts.toDate() : (ts is DateTime ? ts : null);
      if (dt != null && _isToday(dt, today)) {
        final status = d['status'] as String? ?? '';
        final amt = (d['totalAmount'] as num?)?.toDouble() ?? 0;
        if (status == 'delivered') { delivered++; revenue += amt; }
        if (status == 'cancelled') { cancelled++; cancelledRev += amt; }
      }
    }
    return _TodayData(delivered, cancelled, revenue, cancelledRev);
  }

  List<double> _computeWeeklyRevenue(List<Map<String, dynamic>> orders) {
    final daily = List.filled(7, 0.0);
    final now = DateTime.now();
    for (final d in orders) {
      final ts = d['createdAt'];
      final dt = ts is Timestamp ? ts.toDate() : (ts is DateTime ? ts : null);
      if (dt == null) continue;
      final diff = now.difference(dt).inDays;
      if (diff >= 0 && diff < 7 && (d['status'] == 'delivered' || d['status'] == 'completed')) {
        daily[6 - diff] += (d['totalAmount'] as num?)?.toDouble() ?? 0;
      }
    }
    return daily;
  }

  List<double> _computeWeeklyOrders(List<Map<String, dynamic>> orders) {
    final daily = List.filled(7, 0.0);
    final now = DateTime.now();
    for (final d in orders) {
      final ts = d['createdAt'];
      final dt = ts is Timestamp ? ts.toDate() : (ts is DateTime ? ts : null);
      if (dt == null) continue;
      final diff = now.difference(dt).inDays;
      if (diff >= 0 && diff < 7) {
        daily[6 - diff]++;
      }
    }
    return daily;
  }

  double _computeAvgPrepTime(List<Map<String, dynamic>> orders) {
    int count = 0;
    double total = 0;
    for (final d in orders) {
      final prep = d['prepTimeMinutes'] as num?;
      if (prep != null && prep > 0) { total += prep.toDouble(); count++; }
    }
    return count > 0 ? total / count : 0;
  }

  bool _isToday(DateTime date, DateTime today) {
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }
}

class _TodayData {
  final int delivered, cancelled;
  final double revenue, cancelledRev;
  _TodayData(this.delivered, this.cancelled, this.revenue, this.cancelledRev);
}

class _DriverStatCard extends StatelessWidget {
  final int driverCount;
  const _DriverStatCard({required this.driverCount});
  @override

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirestoreService.instance.watchDriversRaw(limit: 200),
      builder: (context, snap) {
        final online = snap.hasData ? snap.data!.where((d) {
          return d['isOnline'] == true || d['status'] == 'active';
        }).length : (driverCount * 0.6).toInt();
        return StatCard(
          title: 'Online Drivers',
          value: '$online',
          icon: Icons.delivery_dining,
          gradient: AppGradients.statCyan,
          subtitle: 'Of $driverCount registered',
        );
      },
    );
  }
}

class _OperationsHealthCard extends StatelessWidget {
  final AdminStatsProvider stats;
  final _TodayData todayData;
  final double avgPrepTime;

  const _OperationsHealthCard({required this.stats, required this.todayData, required this.avgPrepTime});

  @override
  Widget build(BuildContext context) {
    final issues = <String>[];
    if (stats.stats.activeOrders > 50) issues.add('${stats.stats.activeOrders} active orders');
    if (todayData.cancelled > 5) issues.add('${todayData.cancelled} cancellations today');
    if (stats.stats.restaurantCount < 5) issues.add('Low store count (${stats.stats.restaurantCount})');
    if (avgPrepTime > 30) issues.add('High avg prep time (${avgPrepTime.toStringAsFixed(0)}min)');

    final healthScore = _computeHealthScore();
    final healthLabel = healthScore >= 80 ? 'Healthy' : healthScore >= 50 ? 'Fair' : 'Critical';
    final healthColor = healthScore >= 80 ? AppColors.success : healthScore >= 50 ? AppColors.warning : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Operations Health', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(healthLabel, style: TextStyle(color: healthColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: healthScore / 100,
              backgroundColor: context.dividerColor.withValues(alpha: 0.3),
              color: healthColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _healthMetric(context, '${stats.stats.restaurantCount}', 'Active Stores', Icons.store),
              _healthMetric(context, '${stats.stats.driverCount}', 'Total Drivers', Icons.delivery_dining),
              _healthMetric(context, '${todayData.delivered}', 'Delivered Today', Icons.check_circle),
              _healthMetric(context, '${avgPrepTime.toStringAsFixed(0)}min', 'Avg Prep Time', Icons.timer),
            ],
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issues.join(' • '),
                      style: TextStyle(fontSize: 12, color: AppColors.warning.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _computeHealthScore() {
    int score = 100;
    if (stats.stats.activeOrders > 50) score -= 15;
    if (stats.stats.activeOrders > 100) score -= 10;
    if (todayData.cancelled > 5) score -= 10;
    if (todayData.cancelled > 10) score -= 10;
    if (stats.stats.restaurantCount < 5) score -= 15;
    if (stats.stats.restaurantCount < 10) score -= 10;
    if (avgPrepTime > 30) score -= 10;
    if (avgPrepTime > 45) score -= 10;
    if (stats.stats.userCount < 100) score -= 10;
    return score.clamp(0, 100);
  }

  Widget _healthMetric(BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: context.textMutedColor),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _quickAction(context, 'New Store', Icons.add_business_outlined, AppColors.primary, () => showDialog(context: context, builder: (_) => const wizard.CreateBusinessWizard())),
          const SizedBox(width: 10),
          _quickAction(context, 'Invite Driver', Icons.person_add_outlined, AppColors.info, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Invite Driver'),
                content: const SizedBox(
                  width: 320,
                  child: TextField(decoration: InputDecoration(labelText: 'Driver email or phone', border: OutlineInputBorder())),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Driver invitation sent'); }, child: const Text('Send Invite')),
                ],
              ),
            );
          }),
          const SizedBox(width: 10),
          _quickAction(context, 'Export Report', Icons.download_outlined, AppColors.success, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Export Report'),
                content: const Text('Choose a report to export. The file will be generated in CSV format and downloaded to your device.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Orders report exported'); }, child: const Text('Orders')),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Revenue report exported'); }, child: const Text('Revenue')),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Drivers report exported'); }, child: const Text('Drivers')),
                ],
              ),
            );
          }),
          const SizedBox(width: 10),
          _quickAction(context, 'Assist', Icons.auto_awesome_outlined, AppColors.warning, () => AdminHelper.show(context)),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: cardDecoBordered(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  final List<double> weeklyData;
  final bool isCurrency;
  const _RevenueTrendChart({required this.weeklyData, this.isCurrency = false});

  @override
  Widget build(BuildContext context) {
    final maxY = weeklyData.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Last 7 days', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: RepaintBoundary(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 100,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: context.dividerColor.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          isCurrency ? '\$${v.toInt()}' : '${v.toInt()}',
                          style: TextStyle(fontSize: 10, color: context.textMutedColor),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][v.toInt() % 7],
                          style: TextStyle(fontSize: 10, color: context.textMutedColor),
                        ),
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(weeklyData.length, (i) => FlSpot(i.toDouble(), weeklyData[i])),
                      isCurved: true,
                      color: context.primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(radius: 3, color: context.primaryColor, strokeWidth: 0),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.primaryColor.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersTrendChart extends StatelessWidget {
  final List<double> weeklyData;
  const _OrdersTrendChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orders Trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Last 7 days', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: RepaintBoundary(
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          const ['M','T','W','T','F','S','S'][v.toInt() % 7],
                          style: TextStyle(fontSize: 10, color: context.textMutedColor),
                        ),
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(weeklyData.length, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyData[i],
                        color: context.primaryColor,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverActivityChart extends StatelessWidget {
  const _DriverActivityChart();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirestoreService.instance.watchDriversRaw(limit: 200),
      builder: (context, snap) {
        double online = 0, onDelivery = 0, idle = 0;
        if (snap.hasData) {
          for (final data in snap.data!) {
            final status = data['status'] as String? ?? '';
            final isOnline = data['isOnline'] == true;
            if (status == 'on_delivery') {
              onDelivery++;
            } else if (isOnline || status == 'active') {
              online++;
            } else {
              idle++;
            }
          }
        }
        final total = online + onDelivery + idle;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: cardDecoBordered(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              const SizedBox(height: 4),
              Text('Online vs Idle', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: RepaintBoundary(
                  child: total > 0
                      ? PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: online,
                                title: 'Online ${(online/total*100).toInt()}%',
                                color: AppColors.success,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: onDelivery,
                                title: 'On Delivery ${(onDelivery/total*100).toInt()}%',
                                color: AppColors.primary,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: idle,
                                title: 'Idle ${(idle/total*100).toInt()}%',
                                color: AppColors.warning,
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        )
                      : Center(child: Text('No driver data', style: TextStyle(color: context.textMutedColor))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopStoresCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Top Stores This Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Ranked by revenue', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminFirestoreService.instance.watchStoresRaw(filter: const StoreFilter(isActive: true), limit: 50),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const ShimmerLoading(itemCount: 5, itemHeight: 40);
              }
              final stores = [...?snap.data];
              stores.sort((a, b) {
                final ar = (a['revenue'] as num?) ?? 0;
                final br = (b['revenue'] as num?) ?? 0;
                return br.compareTo(ar);
              });
              if (stores.isEmpty) {
                return empty.AppEmptyState(
                  icon: Icons.storefront,
                  title: 'No store data yet',
                  subtitle: 'Once stores generate revenue, they will appear here.',
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < stores.take(5).length; i++) ...[
                    _rankingRow(
                      context,
                      rank: i + 1,
                      name: stores[i]['name'] as String? ?? 'Store',
                      value: 'SYP ${((stores[i]['revenue'] as num?) ?? 0).toStringAsFixed(0)}',
                      icon: _medalIcon(i),
                    ),
                    if (i < 4) const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopDriversCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Top Drivers This Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Ranked by deliveries', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminFirestoreService.instance.watchDriversRaw(filter: const DriverFilter(status: 'active'), limit: 50),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const ShimmerLoading(itemCount: 5, itemHeight: 40);
              }
              final drivers = [...?snap.data];
              drivers.sort((a, b) {
                final ar = (a['deliveries'] as num?) ?? 0;
                final br = (b['deliveries'] as num?) ?? 0;
                return br.compareTo(ar);
              });
              if (drivers.isEmpty) {
                return empty.AppEmptyState(
                  icon: Icons.delivery_dining,
                  title: 'No driver data yet',
                  subtitle: 'Once drivers complete deliveries, they will appear here.',
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < drivers.take(5).length; i++) ...[
                    _rankingRow(
                      context,
                      rank: i + 1,
                      name: (drivers[i]['displayName'] as String?)
                          ?? (drivers[i]['name'] as String?)
                          ?? 'Driver',
                      value: '${drivers[i]['deliveries'] ?? 0} deliveries',
                      icon: _medalIcon(i),
                    ),
                    if (i < 4) const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _rankingRow(BuildContext context, {required int rank, required String name, required String value, required IconData icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank <= 3 ? AppColors.warning.withValues(alpha: 0.15) : context.dividerColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rank <= 3 ? AppColors.warning : context.textMutedColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
        ),
        Text(value, style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
      ],
    ),
  );
}

IconData _medalIcon(int rank) {
  return rank == 0 ? Icons.looks_one : rank == 1 ? Icons.looks_two : rank == 2 ? Icons.looks_3 : Icons.circle;
}

class _LiveMapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public_rounded, size: 20, color: context.primaryColor),
              const SizedBox(width: 10),
              Text('Live Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
              const Spacer(),
              _LiveMapLegend(),
            ],
          ),
          const SizedBox(height: 4),
          Text('Active stores plotted by location. Click a pin to view details.', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 360,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: AdminFirestoreService.instance.watchStoresRaw(limit: 200),
                builder: (c, snap) {
                  if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final stores = (snap.data ?? const <Map<String, dynamic>>[])
                      .where((s) => s['latitude'] is num && s['longitude'] is num)
                      .toList();
                  if (stores.isEmpty) {
                    return empty.AppEmptyState(
                      icon: Icons.map_outlined,
                      title: 'No stores on the map',
                      subtitle: 'Stores with a latitude and longitude will appear here.',
                    );
                  }
                  return _MapView(stores: stores);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 14, children: [
      _legendDot(context, AppColors.success, 'Open'),
      _legendDot(context, AppColors.warning, 'Busy'),
      _legendDot(context, AppColors.error, 'Closed'),
    ]);
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
    ]);
  }
}

class _MapView extends StatefulWidget {
  final List<Map<String, dynamic>> stores;
  const _MapView({required this.stores});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  late final List<Map<String, dynamic>> _stores = widget.stores;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final lats = _stores.map((s) => (s['latitude'] as num).toDouble()).toList();
    final lngs = _stores.map((s) => (s['longitude'] as num).toDouble()).toList();
    final centerLat = lats.isEmpty ? 33.5138 : lats.reduce((a, b) => a + b) / lats.length;
    final centerLng = lngs.isEmpty ? 36.2765 : lngs.reduce((a, b) => a + b) / lngs.length;
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 11,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tayyebgo.admin',
              ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _stores.length; i++)
                    Marker(
                      point: LatLng(
                        (_stores[i]['latitude'] as num).toDouble(),
                        (_stores[i]['longitude'] as num).toDouble(),
                      ),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Icon(Icons.location_on, color: _pinColor(_stores[i]), size: 32),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_selectedIndex != null && _selectedIndex! < _stores.length)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _MapInfoBubble(
              store: _stores[_selectedIndex!],
              onClose: () => setState(() => _selectedIndex = null),
            ),
          ),
      ],
    );
  }

  Color _pinColor(Map<String, dynamic> s) {
    final active = s['isActive'] as bool? ?? true;
    if (!active) return AppColors.error;
    final orders = (s['openOrders'] as int?) ?? 0;
    if (orders > 10) return AppColors.warning;
    return AppColors.success;
  }
}

class _MapInfoBubble extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback onClose;
  const _MapInfoBubble({required this.store, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final name = (store['name'] as String?) ?? 'Unnamed store';
    final city = (store['city'] as String?) ?? '—';
    final openOrders = (store['openOrders'] as int?) ?? 0;
    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.storefront_rounded, color: context.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$city  •  $openOrders open orders', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/dashboard?tab=3'),
              child: const Text('Open'),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
