import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../shared.dart';

class RevenueTrendChart extends StatelessWidget {
  final List<double> weeklyData;
  final bool isCurrency;
  const RevenueTrendChart({required this.weeklyData, this.isCurrency = false});

  @override
  Widget build(BuildContext context) {
    final maxY = weeklyData.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Trend', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Last 7 days', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
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
                      color: context.borderColor.withValues(alpha: 0.3),
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
                          style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][v.toInt() % 7],
                          style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor),
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

class OrdersTrendChart extends StatelessWidget {
  final List<double> weeklyData;
  const OrdersTrendChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orders Trend', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Last 7 days', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
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
                          style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor),
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

class DriverActivityChart extends StatelessWidget {
  const DriverActivityChart();
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
              Text('Driver Activity', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              const SizedBox(height: 4),
              Text('Online vs Idle', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
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
                                color: context.successColor,
                                radius: 50,
                                titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: onDelivery,
                                title: 'On Delivery ${(onDelivery/total*100).toInt()}%',
                                color: context.primaryColor,
                                radius: 50,
                                titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: idle,
                                title: 'Idle ${(idle/total*100).toInt()}%',
                                color: context.warningColor,
                                radius: 50,
                                titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        )
                      : Center(child: Text('No driver data', style: GoogleFonts.inter(color: context.textMutedColor))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
