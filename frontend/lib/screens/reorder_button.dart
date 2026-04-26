import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class ReorderButton extends StatefulWidget {
  const ReorderButton({super.key});

  @override
  State<ReorderButton> createState() => _ReorderButtonState();
}

class _ReorderButtonState extends State<ReorderButton> {
  List<Map<String, dynamic>> _frequentItems = [];
  bool _showPopup = false;

  @override
  void initState() {
    super.initState();
    _loadFrequentItems();
  }

  void _loadFrequentItems() {
    // Demo: Most frequently ordered items
    _frequentItems = [
      {'id': 1, 'name': 'Fresh Milk 1L', 'price': 5.99, 'orderCount': 12},
      {'id': 2, 'name': 'Eggs 12pcs', 'price': 6.99, 'orderCount': 10},
      {'id': 3, 'name': 'Arabic Bread', 'price': 4.99, 'orderCount': 8},
      {'id': 4, 'name': 'Chicken Breast 1kg', 'price': 24.99, 'orderCount': 6},
      {'id': 5, 'name': 'Olive Oil 1L', 'price': 29.99, 'orderCount': 5},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1-Click Reorder Button
            GestureDetector(
              onTap: () => _showReorderPopup(context),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.autorenew, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    const Text('Buy Again', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_frequentItems.length} items', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Tap for 1-click reorder', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _showReorderPopup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double _total = _frequentItems.fold(0, (sum, item) => sum + (item['price'] as double));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.autorenew, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buy Again', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Based on your recent orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),

            // Items List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _frequentItems.length,
                itemBuilder: (context, index) {
                  final item = _frequentItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Checkbox(value: true, onChanged: (_) {}),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Ordered ${item['orderCount']} times', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('SAR ${item['price']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Total and Order Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total (${_frequentItems.length} items)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('SAR ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order placed! Thank you for shopping with us.')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('1-Click Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
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