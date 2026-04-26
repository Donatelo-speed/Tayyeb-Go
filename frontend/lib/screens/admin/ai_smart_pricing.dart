import 'package:flutter/material.dart';
import 'dart:math';

class AISmartPricing extends StatefulWidget {
  const AISmartPricing({super.key});

  @override
  State<AISmartPricing> createState() => _AISmartPricingState();
}

class _AISmartPricingState extends State<AISmartPricing> {
  // Demo products with AI analysis
  final List<Map<String, dynamic>> _products = [
    {'id': 1, 'name': 'Fresh Chicken 1kg', 'currentPrice': 24.99, 'suggestedPrice': 22.99, 'sales': 450, 'direction': 'lower', 'reason': 'Low demand in last 30 days'},
    {'id': 2, 'name': 'Olive Oil 1L', 'currentPrice': 29.99, 'suggestedPrice': 34.99, 'sales': 180, 'direction': 'raise', 'reason': 'High demand + limited stock'},
    {'id': 3, 'name': 'Milk 1L', 'currentPrice': 5.99, 'suggestedPrice': 5.99, 'sales': 1200, 'direction': 'maintain', 'reason': 'Optimal pricing'},
    {'id': 4, 'name': 'Arabic Bread', 'currentPrice': 4.99, 'suggestedPrice': 5.49, 'sales': 320, 'direction': 'raise', 'reason': 'Rising material costs'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            const Text('Smart Pricing'),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _AIPricingCard(product: product, isDark: isDark);
        },
      ),
    );
  }
}

class _AIPricingCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isDark;

  const _AIPricingCard({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final direction = product['direction'];
    final color = direction == 'raise' ? Colors.green : direction == 'lower' ? Colors.red : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: direction != 'maintain' ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      direction == 'raise' ? Icons.trending_up : direction == 'lower' ? Icons.trending_down : Icons.trending_flat,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      direction == 'raise' ? '+${((product['suggestedPrice'] - product['currentPrice']) / product['currentPrice'] * 100).toStringAsFixed(0)}%' : 
                      direction == 'lower' ? '${((product['currentPrice'] - product['suggestedPrice']) / product['currentPrice'] * 100).toStringAsFixed(0)}%' : '0%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('SAR ${product['currentPrice']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 24),
              Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Suggested', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('SAR ${product['suggestedPrice']}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product['reason'],
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Ignore'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: const Text('Apply Price'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}