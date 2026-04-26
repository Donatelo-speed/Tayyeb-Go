import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AdminExecutiveDashboard extends StatefulWidget {
  const AdminExecutiveDashboard({super.key});

  @override
  State<AdminExecutiveDashboard> createState() => _AdminExecutiveDashboardState();
}

class _AdminExecutiveDashboardState extends State<AdminExecutiveDashboard> {
  // Real-time stats
  Map<String, dynamic> _stats = {
    'todayRevenue': 45280.50,
    'activeOrders': 42,
    'onlineDrivers': 15,
    'lowStockProducts': 23,
  };

  List<Map<String, dynamic>> _lowStockItems = [];
  List<Map<String, dynamic>> _ordersByZone = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          // Simulate real-time updates
          _stats = {
            ..._stats,
            'activeOrders': _stats['activeOrders'] + (DateTime.now().second % 3 == 0 ? 1 : 0),
            'todayRevenue': _stats['todayRevenue'] + (DateTime.now().second % 5 == 0 ? 15.0 : 0),
          };
        });
      }
    });
  }

  void _loadData() {
    // Load low stock items
    _lowStockItems = [
      {'id': 1, 'name': 'Fresh Chicken', 'stock': 5, 'minStock': 10},
      {'id': 2, 'name': 'Olive Oil 1L', 'stock': 8, 'minStock': 15},
      {'id': 3, 'name': 'Milk 1L', 'stock': 3, 'minStock': 20},
      {'id': 4, 'name': 'Eggs 12pcs', 'stock': 2, 'minStock': 10},
    ];

    // Orders by zone (for heatmap)
    _ordersByZone = [
      {'zone': 'Al Olaya', 'orders': 45},
      {'zone': 'King Abdullah', 'orders': 38},
      {'zone': 'Al Malaz', 'orders': 28},
      {'zone': 'Alizza', 'orders': 22},
      {'zone': 'North Riyadh', 'orders': 18},
    ];
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          _buildAppBar(isDark),

          // Bento Grid Stats
          SliverToBoxAdapter(child: _buildBentoGrid(isDark)),

          // Stock Alerts
          SliverToBoxAdapter(child: _buildStockAlerts(isDark)),

          // Revenue Chart
          SliverToBoxAdapter(child: _buildRevenueChart(isDark)),

          // Heatmap
          SliverToBoxAdapter(child: _buildHeatmap(isDark)),

          // Bulk Import
          SliverToBoxAdapter(child: _buildBulkImport(isDark)),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Control Tower', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)] : [Colors.white, Colors.grey[50]!],
            ),
          ),
        ),
      ),
      actions: [
        // Live indicator
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('LIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Revenue Card
          _BentoCard(
            title: "Today's Revenue",
            value: 'SAR ${_stats['todayRevenue']?.toStringAsFixed(0)}',
            trend: '+12%',
            icon: Icons.attach_money,
            color: Colors.green,
            onTap: () {},
          ),

          // Active Orders
          _BentoCard(
            title: 'Active Orders',
            value: '${_stats['activeOrders']}',
            trend: '+5',
            icon: Icons.shopping_bag,
            color: Colors.blue,
            onTap: () {},
          ),

          // Online Drivers
          _BentoCard(
            title: 'Drivers Online',
            value: '${_stats['onlineDrivers']}',
            icon: Icons.local_shipping,
            color: Colors.orange,
            onTap: () {},
          ),

          // Low Stock Alert
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 170,
              height: 130,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _stats['lowStockProducts'] > 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: _stats['lowStockProducts'] > 0 ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: _stats['lowStockProducts'] > 0 ? Colors.red : Colors.green,
                  ),
                  const Spacer(),
                  Text(
                    '${_stats['lowStockProducts']}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  Text('Low Stock Items', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAlerts(bool isDark) {
    if (_lowStockItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text('Stock Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${_lowStockItems.length} items', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...(_lowStockItems.take(3).map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item['stock']} left',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.trending_down, color: Colors.red, size: 16),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(bool isDark) {
    final weekData = [12500, 15800, 14200, 18900, 21000, 19500, _stats['todayRevenue'] ?? 45280];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue This Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 50000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[value.toInt()], style: TextStyle(color: Colors.grey[600], fontSize: 12));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: weekData.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: e.key == 6 ? Colors.green : Colors.blue,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(bool isDark) {
    // Order zones visualization
    final maxOrders = _ordersByZone.map((z) => z['orders'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Order Hot Zones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Riyadh', style: const TextStyle(color: Colors.purple, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_ordersByZone.map((zone) {
            final intensity = (zone['orders'] as int) / maxOrders;
            final color = Color.lerp(Colors.purple.withOpacity(0.1), Colors.purple, intensity)!;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    child: Text(zone['zone'], style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: intensity,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${zone['orders']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildBulkImport(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Bulk Action Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Drag & drop CSV/Excel to update prices or stock for 1,000+ items at once', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          _BulkDropZone(),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BentoCard({required this.title, required this.value, this.trend, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252542) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(trend!, style: const TextStyle(color: Colors.green, fontSize: 10)),
                  ),
              ],
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BulkDropZone extends StatefulWidget {
  @override
  State<_BulkDropZone> createState() => _BulkDropZoneState();
}

class _BulkDropZoneState extends State<_BulkDropZone> {
  bool _isDragging = false;
  List<List<dynamic>>? _previewData;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickFile,
      onDragEnter: (_) => setState(() => _isDragging = true),
      onDragExit: (_) => setState(() => _isDragging = false),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: _isDragging ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDragging ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: _previewData != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(height: 4),
                    Text('${_previewData!.length} rows ready', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_previewData!.isNotEmpty ? 'Columns: ${_previewData![0].join(', ')}' : '', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, color: _isDragging ? Theme.of(context).colorScheme.primary : Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(_isDragging ? 'Drop file here' : 'Drag CSV or Excel here', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
        ),
      ),
    );
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final contents = await file.readAsString();
      _previewData = const CsvToListConverter().convert(contents);
      setState(() {});
    }
  }
}