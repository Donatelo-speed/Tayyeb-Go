import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
import '../../../core/services/admin_firestore_service.dart';
import 'shared.dart';
import 'widgets/charts.dart';
import 'widgets/data_models.dart';
import 'widgets/health_card.dart';
import 'widgets/map_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/ranking_cards.dart';
import 'widgets/stats_card.dart';

const _statOrange = LinearGradient(colors: [AppColors.primary, AppColors.primaryHover], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _statGreen = LinearGradient(colors: [AppColors.driverAccent, const Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _statPurple = LinearGradient(colors: [AppColors.adminAccent, const Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _statBlue = LinearGradient(colors: [AppColors.cyan, const Color(0xFF0891B2)], begin: Alignment.topLeft, end: Alignment.bottomRight);

class DashboardView extends StatelessWidget {
  const DashboardView();

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AdminStatsProvider>();
    return pageContainer(context, child: Scaffold(
        backgroundColor: context.backgroundColor,
      body: stats.loading
          ? const TGSGroup(lines: 4)
          : stats.error != null
              ? Center(
                  child: TGErrorWidget(
                    message: stats.error!,
                    onRetry: () => stats.refresh(),
                  ),
                )
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: AdminFirestoreService.instance.watchOrdersRaw(limit: 500),
                  builder: (context, ordersSnap) {
                    if (ordersSnap.connectionState == ConnectionState.waiting && !ordersSnap.hasData) {
                      return const TGSGroup(lines: 4);
                    }
                    if (ordersSnap.hasError) {
                      return TGEmptyState(
                        icon: Icons.error_outline,
                        title: 'Could not load orders',
                        description: ordersSnap.error.toString(),
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
                                StaggerItem(index: 1, child: const QuickActionsRow()),
                                const SizedBox(height: 24),
                                StaggerItem(index: 2, child: _buildStatCards(context, stats, todayData)),
                                const SizedBox(height: 24),
                                StaggerItem(index: 3, child: OperationsHealthCard(stats: stats, todayData: todayData, avgPrepTime: avgPrep)),
                                const SizedBox(height: 24),
                                StaggerItem(index: 4, child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 800) {
                                      return Column(children: [
                                        const TopStoresCard(),
                                        const SizedBox(height: 16),
                                        const TopDriversCard(),
                                      ]);
                                    }
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: const TopStoresCard()),
                                        const SizedBox(width: 24),
                                        Expanded(child: const TopDriversCard()),
                                      ],
                                    );
                                  },
                                )),
                                const SizedBox(height: 24),
                                StaggerItem(index: 5, child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 600) {
                                      return Column(children: [
                                        RevenueTrendChart(weeklyData: weeklyRevenue, isCurrency: true),
                                        const SizedBox(height: 24),
                                        OrdersTrendChart(weeklyData: weeklyOrders),
                                      ]);
                                    }
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 3, child: RevenueTrendChart(weeklyData: weeklyRevenue, isCurrency: true)),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 2, child: OrdersTrendChart(weeklyData: weeklyOrders)),
                                      ],
                                    );
                                  },
                                )),
                                const SizedBox(height: 24),
                                StaggerItem(index: 6, child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 600) {
                                      return Column(children: [
                                        const DriverActivityChart(),
                                        const SizedBox(height: 24),
                                        SizedBox(height: 300, child: AppActivityFeed(limit: 6)),
                                      ]);
                                    }
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 2, child: const DriverActivityChart()),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 3, child: SizedBox(height: 300, child: AppActivityFeed(limit: 6))),
                                      ],
                                    );
                                  },
                                )),
                                const SizedBox(height: 24),
                                StaggerItem(index: 7, child: const LiveMapCard()),
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
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryHover],
              ).createShader(bounds),
              child: Text('Command Center', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: Colors.white, letterSpacing: 0)),
            ),
            const SizedBox(height: 4),
            Text('Your platform at a glance', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, AdminStatsProvider stats, TodayData t) {
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
            StatCard(title: 'Active Orders', value: '${stats.stats.activeOrders}', icon: Icons.shopping_bag_rounded, gradient: _statOrange, subtitle: 'In progress'),
            StatCard(title: 'Delivered Today', value: '${t.delivered}', icon: Icons.check_circle_rounded, gradient: _statGreen, subtitle: 'Completed'),
            StatCard(title: 'Revenue Today', value: '\$${t.revenue.toStringAsFixed(0)}', icon: Icons.attach_money_rounded, gradient: _statPurple, subtitle: 'Gross revenue'),
            DriverStatCard(driverCount: stats.stats.driverCount),
            StatCard(title: 'Active Stores', value: '${stats.stats.restaurantCount}', icon: Icons.store_rounded, gradient: _statBlue),
            StatCard(title: 'Total Customers', value: '${stats.stats.userCount}', icon: Icons.people_rounded, gradient: _statGreen),
            StatCard(title: 'Cancelled', value: '${t.cancelled}', icon: Icons.cancel_rounded, gradient: _statPurple, subtitle: '\$${t.cancelledRev.toStringAsFixed(0)} refunded'),
            StatCard(title: 'Pending Payouts', value: '\$${stats.stats.pendingPayouts.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, gradient: _statOrange),
          ],
        );
      },
    );
  }

  TodayData _computeTodayData(List<Map<String, dynamic>> orders) {
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
    return TodayData(delivered, cancelled, revenue, cancelledRev);
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
