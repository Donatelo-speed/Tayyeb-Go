import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int? orderId;
  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await _api.getOrder(widget.orderId ?? 0);
      if (mounted) {
        setState(() {
          _order = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    if (mounted) {
      setState(() {
        _order = {
          'id': 101,
          'status': 'shipped',
          'customer_name': 'Demo User',
          'customer_phone': '555-1234',
          'shipping_address': '123 Main St, New York, NY 10001',
          'total_amount': '75.99',
          'estimated_delivery': '25 min',
          'items': [
            {'name': 'Wireless Headphones', 'quantity': 2, 'price': '59.98'},
            {'name': 'Phone Case', 'quantity': 1, 'price': '15.99'},
          ],
          'driver': {
            'name': 'John Driver',
            'phone': '555-9999',
            'current_location': {'lat': 40.7200, 'lng': -74.0100},
          },
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order?['id'] ?? ''}'),
        actions: [
          if (_order?['status'] != 'delivered')
            IconButton(icon: const Icon(Icons.help_outline), onPressed: _showHelp),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.local_shipping, size: 48, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(
                            'Order Status: ${_order?['status'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Estimated delivery: ${_order?['estimated_delivery'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _DetailCard(
                    title: 'Delivery Address',
                    content: _order?['shipping_address'] ?? '',
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    title: 'Items (${_order?['items']?.length ?? 0})',
                    content: _order?['items']?.map((i) => '${i['name']} x${i['quantity']}').join('\n') ?? '',
                    icon: Icons.shopping_bag,
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    title: 'Total',
                    content: '\$${_order?['total_amount']}',
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 24),
                  if (_order?['driver'] != null) ...[
                    const Text('Driver Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 24, backgroundColor: Colors.green, child: const Icon(Icons.person, color: Colors.white)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_order!['driver']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Delivery Partner', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.message),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need Help?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Chat with Support'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _DetailCard({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}