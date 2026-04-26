import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/omni_theme.dart';

class RevenueChart extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isDark;

  const RevenueChart({super.key, this.stats, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? const Color(0xFF00FFC2) : const Color(0xFFFF6B6B);
    final secondaryColor = isDark ? const Color(0xFF6C5CE7) : const Color(0xFF6C5CE7);
    final textColor = isDark ? Colors.white : Colors.black87;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Revenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('+12.5%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$${((stats?['revenue'] ?? 125000) as num).toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(),
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.1)),
                  ),
                ],
                lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipColor: (_) => _getCardColor(context))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    final now = DateTime.now();
    return List.generate(7, (i) => FlSpot(i.toDouble(), (10000 + (i * 2500) + (i * 500)).toDouble()));
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252542) : Colors.white;
  }
}

class OrdersChart extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const OrdersChart({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00FFC2) : const Color(0xFFFF6B6B);

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${stats?['totalOrders'] ?? 3420}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 500,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[value.toInt() % 7], style: TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _generateBarGroups(isDark, primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(bool isDark, Color color) {
    return List.generate(7, (i) => BarChartGroupData(x: i, barRods: [
      BarChartRodData(
        toY: (200 + (i * 50)).toDouble(),
        color: i == 6 ? color : color.withOpacity(0.6),
        width: 16,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    ]));
  }
}

class StatsGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const StatsGrid({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Products', value: '${stats?['totalProducts'] ?? 5000}', icon: Icons.inventory, color: isDark ? Colors.blue : Colors.blueAccent)),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(label: 'Customers', value: '${stats?['totalUsers'] ?? 1250}', icon: Icons.people, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Drivers', value: '${stats?['activeDrivers'] ?? 15}', icon: Icons.local_shipping, color: Colors.teal)),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(label: 'Pending', value: '${stats?['pendingDrivers'] ?? 3}', icon: Icons.hourglass_empty, color: Colors.amber)),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverMapPlaceholder extends StatelessWidget {
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> orders;

  const DriverMapPlaceholder({super.key, required this.drivers, required this.orders});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDrivers = drivers.where((d) => d['status'] == 'active').toList();
    final pendingOrders = orders.where((o) => o['status'] == 'processing').toList();

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              PulseBadge(label: '${activeDrivers.length} Active', color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text('Add Google Maps API Key', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    ...activeDrivers.asMap().entries.map((entry) {
                      final driver = entry.value;
                      final x = 80.0 + (entry.key * 50) % 150;
                      final y = 80.0 + (entry.key * 70) % 100;
                      return Positioned(
                        left: x,
                        top: y,
                        child: GestureDetector(
                          onTap: () => _showDriverSheet(context, driver),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('${pendingOrders.length} Pending Deliveries', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  void _showDriverSheet(BuildContext context, Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Location: ${driver['current_location'] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.phone), onPressed: () {}, label: const Text('Call'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(icon: const Icon(Icons.message), onPressed: () {}, label: const Text('Message'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}