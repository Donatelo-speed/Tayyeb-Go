import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/partner_role_controller.dart';

enum DateRange { today, sevenDays, thirtyDays, allTime }

class PartnerAnalyticsScreen extends StatefulWidget {
  const PartnerAnalyticsScreen({super.key});

  @override
  State<PartnerAnalyticsScreen> createState() => _PartnerAnalyticsScreenState();
}

class _PartnerAnalyticsScreenState extends State<PartnerAnalyticsScreen> {
  DateRange _selectedRange = DateRange.sevenDays;

  DateTime _getRangeStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedRange) {
      case DateRange.today:
        return today;
      case DateRange.sevenDays:
        return today.subtract(const Duration(days: 6));
      case DateRange.thirtyDays:
        return today.subtract(const Duration(days: 29));
      case DateRange.allTime:
        return DateTime(2020);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantId = context.read<PartnerRoleController>().restaurantId;
    final rangeStart = _getRangeStart();

    Query ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);
    if (restaurantId != null) {
      ordersQuery = ordersQuery.where('restaurantId', isEqualTo: restaurantId);
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.partnerAccent, AppColors.warning],
          ).createShader(bounds),
          child: Text(
            'Analytics',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _DateRangeSelector(
              selected: _selectedRange,
              onChanged: (r) => setState(() => _selectedRange = r),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery.limit(1000).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoader());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: TGEmptyState(
                icon: Icons.analytics_outlined,
                title: 'No data yet',
                description: 'Analytics will appear once orders start coming in',
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final filtered = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final ts = (d['createdAt'] as Timestamp?)?.toDate();
            return ts != null && !ts.isBefore(rangeStart);
          }).toList();

          return _buildAnalyticsBody(filtered);
        },
      ),
    );
  }

  Widget _buildAnalyticsBody(List<QueryDocumentSnapshot> docs) {
    double totalRevenue = 0;
    int totalOrders = docs.length;
    int dineInCount = 0;
    int deliveryCount = 0;
    int pickupCount = 0;
    final Map<String, int> itemQuantity = {};
    final Map<String, double> itemRevenue = {};
    final Map<String, double> dailyRevenue = {};
    final Map<String, int> dailyOrders = {};

    final now = DateTime.now();
    final rangeStart = _getRangeStart();
    final daysDiff = now.difference(rangeStart).inDays;
    final displayDays = _selectedRange == DateRange.today ? 1 : (daysDiff + 1).clamp(1, 30);

    for (var i = displayDays - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = '${day.month}/${day.day}';
      dailyRevenue[key] = 0;
      dailyOrders[key] = 0;
    }

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
      totalRevenue += amount;

      final fulfillment = (d['fulfillmentType'] as String?) ?? 'dine-in';
      if (fulfillment == 'delivery') {
        deliveryCount++;
      } else if (fulfillment == 'pickup') {
        pickupCount++;
      } else {
        dineInCount++;
      }

      final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dayKey = '${createdAt.month}/${createdAt.day}';
        dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
        dailyOrders[dayKey] = (dailyOrders[dayKey] ?? 0) + 1;
      }

      if (d['items'] is List) {
        for (final item in d['items'] as List) {
          final name = item['name'] as String? ?? '';
          if (name.isEmpty) continue;
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? 0;
          itemQuantity[name] = (itemQuantity[name] ?? 0) + qty;
          itemRevenue[name] = (itemRevenue[name] ?? 0) + (price * qty);
        }
      }
    }

    final sortedItems = itemQuantity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topItems = sortedItems.take(5).toList();
    final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final topItemName = topItems.isNotEmpty ? topItems.first.key : '—';

    final orderedDailyRevenue = dailyRevenue.entries.toList();
    final orderedDailyOrders = dailyOrders.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCards(
          totalRevenue: totalRevenue,
          totalOrders: totalOrders,
          avgOrder: avgOrder,
          topItem: topItemName,
        ),
        const SizedBox(height: 20),
        Text(
          'Revenue Trend',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _RevenueChart(data: orderedDailyRevenue),
        const SizedBox(height: 24),
        Text(
          'Orders Count',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _OrdersChart(data: orderedDailyOrders),
        const SizedBox(height: 24),
        Text(
          'Revenue Breakdown',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _BreakdownCard(
          dineIn: dineInCount,
          delivery: deliveryCount,
          pickup: pickupCount,
        ),
        const SizedBox(height: 24),
        Text(
          'Top Selling Items',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _TopItemsList(items: topItems, maxQty: topItems.isNotEmpty ? topItems.first.value : 1),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Summary Cards ──

class _SummaryCards extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;
  final double avgOrder;
  final String topItem;

  const _SummaryCards({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrder,
    required this.topItem,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          context,
          'Total Revenue',
          '\$${totalRevenue.toStringAsFixed(0)}',
          Icons.attach_money_rounded,
          context.successColor,
        ),
        _statCard(
          context,
          'Total Orders',
          '$totalOrders',
          Icons.shopping_bag_rounded,
          context.warningColor,
        ),
        _statCard(
          context,
          'Avg Order',
          '\$${avgOrder.toStringAsFixed(2)}',
          Icons.receipt_long_rounded,
          context.primaryColor,
        ),
        _statCard(
          context,
          'Top Item',
          topItem,
          Icons.star_rounded,
          AppColors.accent,
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              color: context.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Range Selector ──

class _DateRangeSelector extends StatelessWidget {
  final DateRange selected;
  final ValueChanged<DateRange> onChanged;

  const _DateRangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DateRange.values.map((range) {
        final isActive = range == selected;
        final label = switch (range) {
          DateRange.today => 'Today',
          DateRange.sevenDays => '7 Days',
          DateRange.thirtyDays => '30 Days',
          DateRange.allTime => 'All Time',
        };
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? context.warningColor
                    : context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? context.warningColor
                      : context.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : context.textMutedColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Revenue Line Chart ──

class _RevenueChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;

  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 100 : (maxY * 1.2),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 25 : (maxY / 4),
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.borderColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    '\${value.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.textMutedColor,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  if (data.length > 7 && idx % ((data.length / 5).ceil()) != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[idx].key,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: context.textMutedColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.surfaceColor,
              tooltipRoundedRadius: 10,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(0)}',
                    GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.warningColor,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: context.warningColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length <= 10,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: context.warningColor,
                    strokeColor: context.surfaceColor,
                    strokeWidth: 2,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.warningColor.withValues(alpha: 0.2),
                    context.warningColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orders Bar Chart ──

class _OrdersChart extends StatelessWidget {
  final List<MapEntry<String, int>> data;

  const _OrdersChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < data.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i].value.toDouble(),
              color: context.successColor,
              width: data.length > 14 ? 6 : 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY == 0 ? 10 : (maxY * 1.2),
                color: context.borderColor.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : (maxY * 1.2),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 2.5 : (maxY / 4).toDouble(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.borderColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    '${value.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.textMutedColor,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  if (data.length > 7 && idx % ((data.length / 5).ceil()) != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[idx].key,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: context.textMutedColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.surfaceColor,
              tooltipRoundedRadius: 10,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} orders',
                  GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.successColor,
                  ),
                );
              },
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }
}

// ── Revenue Breakdown ──

class _BreakdownCard extends StatelessWidget {
  final int dineIn;
  final int delivery;
  final int pickup;

  const _BreakdownCard({
    required this.dineIn,
    required this.delivery,
    required this.pickup,
  });

  @override
  Widget build(BuildContext context) {
    final total = dineIn + delivery + pickup;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
        ),
        child: Text(
          'No orders yet',
          style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor),
        ),
      );
    }

    final dineInPct = (dineIn / total * 100).toStringAsFixed(0);
    final deliveryPct = (delivery / total * 100).toStringAsFixed(0);
    final pickupPct = (pickup / total * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: [
                  if (dineIn > 0)
                    PieChartSectionData(
                      value: dineIn.toDouble(),
                      color: context.primaryColor,
                      radius: 40,
                      title: '$dineInPct%',
                      titleStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (delivery > 0)
                    PieChartSectionData(
                      value: delivery.toDouble(),
                      color: context.warningColor,
                      radius: 40,
                      title: '$deliveryPct%',
                      titleStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (pickup > 0)
                    PieChartSectionData(
                      value: pickup.toDouble(),
                      color: context.cyanColor,
                      radius: 40,
                      title: '$pickupPct%',
                      titleStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(context, 'Dine-In', dineIn, context.primaryColor),
              _legendItem(context, 'Delivery', delivery, context.warningColor),
              _legendItem(context, 'Pickup', pickup, context.cyanColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

// ── Top Items List ──

class _TopItemsList extends StatelessWidget {
  final List<MapEntry<String, int>> items;
  final int maxQty;

  const _TopItemsList({required this.items, required this.maxQty});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
        ),
        child: Text(
          'No item data yet',
          style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor),
        ),
      );
    }

    final medals = [AppColors.warning, AppColors.textTertiary, AppColors.accent];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final entry = items[i];
          final ratio = maxQty > 0 ? entry.value / maxQty : 0.0;
          final medal = i < medals.length ? medals[i] : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (medal != null)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: medal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: medal,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(width: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: context.borderColor.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            i == 0
                                ? context.warningColor
                                : i == 1
                                    ? context.primaryColor
                                    : context.cyanColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${entry.value} sold',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
