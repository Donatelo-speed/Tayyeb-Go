import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DriverEarningsWallet extends StatefulWidget {
  const DriverEarningsWallet({super.key});

  @override
  State<DriverEarningsWallet> createState() => _DriverEarningsWalletState();
}

class _DriverEarningsWalletState extends State<DriverEarningsWallet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Demo earnings data
  final double _totalEarnings = 1250.50;
  final double _pendingCashout = 350.00;
  
  List<Map<String, dynamic>> _dailyEarnings = [
    {'day': 'Mon', 'amount': 180.50},
    {'day': 'Tue', 'amount': 220.00},
    {'day': 'Wed', 'amount': 195.00},
    {'day': 'Thu', 'amount': 280.50},
    {'day': 'Fri', 'amount': 175.00},
    {'day': 'Sat', 'amount': 120.00},
    {'day': 'Sun', 'amount': 79.50},
  ];

  List<Map<String, dynamic>> _recentCashouts = [
    {'id': 1, 'amount': 500.00, 'date': '2024-01-15', 'status': 'paid'},
    {'id': 2, 'amount': 350.00, 'date': '2024-01-10', 'status': 'paid'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00B894), const Color(0xFF00CEC9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF00B894).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('SAR ${_totalEarnings.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('SAR ${_pendingCashout.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Pending', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.white30),
                    Column(
                      children: [
                        Text('SAR ${(_totalEarnings - _pendingCashout).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Available', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestCashout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00B894),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cash Out Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'This Week'),
              Tab(text: 'Cash Out History'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Earnings Chart
                Padding(
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
                        const Text('Daily Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 350,
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
                              barGroups: _dailyEarnings.asMap().entries.map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value['amount'],
                                    color: const Color(0xFF00B894),
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
                  ),
                ),

                // Cash Out History
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recentCashouts.length,
                  itemBuilder: (context, index) {
                    final cashout = _recentCashouts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252542) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cashout['status'] == 'paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              cashout['status'] == 'paid' ? Icons.check_circle : Icons.hourglass_empty,
                              color: cashout['status'] == 'paid' ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SAR ${cashout['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(cashout['date'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cashout['status'] == 'paid' ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cashout['status'] == 'paid' ? 'Paid' : 'Pending',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _requestCashout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Cash Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: SAR ${(_totalEarnings - _pendingCashout).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Enter your bank account details in Profile settings to receive the funds.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cash out request submitted!')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}