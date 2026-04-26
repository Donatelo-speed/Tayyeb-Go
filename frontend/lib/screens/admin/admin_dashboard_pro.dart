import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';

class AdminDashboardPro extends StatefulWidget {
  const AdminDashboardPro({super.key});

  @override
  State<AdminDashboardPro> createState() => _AdminDashboardProState();
}

class _AdminDashboardProState extends State<AdminDashboardPro> {
  // Real-time stats (simulated WebSocket)
  StreamController<Map<String, dynamic>>? _statsController;
  Timer? _realtimeTimer;
  
  Map<String, dynamic> _stats = {
    'totalRevenue': 125000.0,
    'activeOrders': 42,
    'activeDrivers': 15,
    'totalProducts': 5000,
    'todayOrders': 128,
    'pendingOrders': 12,
  };
  
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topProducts = [];
  String? _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    _startRealtimeUpdates();
    _loadData();
  }

  void _startRealtimeUpdates() {
    // Simulate WebSocket real-time updates
    _realtimeTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _stats = {
            ..._stats,
            'activeOrders': _stats['activeOrders'] + (DateTime.now().second % 3 == 0 ? 1 : 0),
            'totalRevenue': _stats['totalRevenue'] + (DateTime.now().second % 5 == 0 ? 15.50 : 0),
          };
        });
      }
    });
  }

  void _loadData() {
    // Demo data
    _recentOrders = [
      {'id': 1, 'customer': 'Ahmed K.', 'total': 89.99, 'status': 'processing', 'time': '2 min ago'},
      {'id': 2, 'customer': 'Sarah M.', 'total': 45.50, 'status': 'shipped', 'time': '5 min ago'},
      {'id': 3, 'customer': 'Mohammed A.', 'total': 156.00, 'status': 'delivered', 'time': '10 min ago'},
    ];
    
    _topProducts = [
      {'name': 'Fresh Chicken', 'sales': 450, 'revenue': 11247.50},
      {'name': 'Olive Oil', 'sales': 380, 'revenue': 11396.20},
      {'name': 'Milk 1L', 'sales': 320, 'revenue': 1916.80},
    ];
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _statsController?.close();
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
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: isDark ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)] : [Colors.white, Colors.grey[50]!))),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
              IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
            ],
          ),

          // Bento Grid Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Real-Time Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Bento Grid Layout
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _BentoCard(
                        title: 'Gross Revenue',
                        value: 'SAR ${_stats['totalRevenue']?.toStringAsFixed(2)}',
                        subtitle: '+12% from yesterday',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        size: isDark ? const Size(180, 120) : const Size(160, 110),
                        onTap: () {},
                      ),
                      _BentoCard(
                        title: 'Active Orders',
                        value: '${_stats['activeOrders']}',
                        subtitle: '${_stats['pendingOrders']} pending',
                        icon: Icons.shopping_bag,
                        color: Colors.orange,
                        size: isDark ? const Size(180, 120) : const Size(160, 110),
                        onTap: () {},
                      ),
                      _BentoCard(
                        title: 'Active Drivers',
                        value: '${_stats['activeDrivers']}',
                        subtitle: 'Online now',
                        icon: Icons.local_shipping,
                        color: Colors.blue,
                        size: isDark ? const Size(180, 120) : const Size(160, 110),
                        onTap: () {},
                      ),
                      _BentoCard(
                        title: 'Products',
                        value: '${_stats['totalProducts']}',
                        subtitle: 'In catalog',
                        icon: Icons.inventory,
                        color: Colors.purple,
                        size: isDark ? const Size(180, 120) : const Size(160, 110),
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Revenue Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252542) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Revenue Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'today', label: Text('Today')),
                            ButtonSegment(value: 'week', label: Text('Week')),
                            ButtonSegment(value: 'month', label: Text('Month')),
                          ],
                          selected: {_selectedPeriod ?? 'today'},
                          onSelectionChanged: (s) => setState(() => _selectedPeriod = s.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(7, (i) => FlSpot(i.toDouble(), (i * 15 + 50).toDouble())),
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bulk Import Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252542) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Bulk Product Import', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Upload Excel/CSV to import products. Auto-matches columns: Name, Price, Category', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    _DragDropZone(),
                  ],
                ),
              ),
            ),
          ),

          // Live Driver Map Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252542) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Live Driver Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text('${_stats['activeDrivers']} drivers online', style: const TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _LiveMapPlaceholder(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent Orders
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252542) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...(_recentOrders.map((order) => _RecentOrderTile(order: order, isDark: isDark))),
                  ],
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Size size;
  final VoidCallback onTap;

  const _BentoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252542) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(subtitle, style: TextStyle(color: color, fontSize: 10)),
              ],
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DragDropZone extends StatefulWidget {
  @override
  State<_DragDropZone> createState() => _DragDropZoneState();
}

class _DragDropZoneState extends State<_DragDropZone> {
  bool _isDragging = false;
  List<List<dynamic>>? _csvData;
  String? _error;
  
  void _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final csv = const CsvToListConverter().convert(contents);
        
        setState(() {
          _csvData = csv;
          _error = null;
        });
        
        _showPreview();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _showPreview() {
    if (_csvData == null || _csvData!.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview (${_csvData!.length} rows)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  children: _csvData!.take(5).map((row) => TableRow(
                    children: row.map((cell) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('$cell'),
                    )).toList(),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${_csvData!.length} products'))));
                },
                child: const Text('Import Products'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickFile,
      onDragEnter: (_) => setState(() => _isDragging = true),
      onDragExit: (_) => setState(() => _isDragging = false),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: _isDragging ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDragging ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload, color: _isDragging ? Theme.of(context).colorScheme.primary : Colors.grey[400], size: 40),
              const SizedBox(height: 8),
              Text(_isDragging ? 'Drop file here' : 'Drag & drop CSV/Excel or tap to browse', style: TextStyle(color: Colors.grey[600])),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveMapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Add Google Maps API Key', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          // Sample driver markers
          ...List.generate(3, (i) => Positioned(
            left: 50.0 + i * 80,
            top: 60.0 + i * 40,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: i == 0 ? Colors.green : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
            ),
          )),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDark;

  const _RecentOrderTile({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(order['customer'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('SAR ${order['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(order['time'], style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (order['status']) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'processing': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (order['status']) {
      case 'delivered': return Icons.check_circle;
      case 'shipped': return Icons.local_shipping;
      case 'processing': return Icons.hourglass_empty;
      default: return Icons.receipt;
    }
  }
}