import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'order_tracking_screen.dart';

class OrderItem {
  final int id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final List<OrderItemProduct> items;

  OrderItem({required this.id, required this.totalAmount, required this.status, required this.createdAt, required this.items});
  
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      items: json['items'] != null ? (json['items'] as List).map((i) => OrderItemProduct.fromJson(i)).toList() : [],
    );
  }
}

class OrderItemProduct {
  final String name;
  final int quantity;
  final double price;

  OrderItemProduct({required this.name, required this.quantity, required this.price});
  
  factory OrderItemProduct.fromJson(Map<String, dynamic> json) {
    return OrderItemProduct(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderItem> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiEndpoints.get('/orders', token: authProvider.token);
      if (result['success'] == true && result['orders'] != null) {
        _orders = (result['orders'] as List).map((o) => OrderItem.fromJson(o)).toList();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final canTrack = order.status == 'processing' || order.status == 'picked_up' || order.status == 'shipped';
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order.status),
                          child: Icon(_getStatusIcon(order.status), color: Colors.white),
                        ),
                        title: Text('Order #${order.id}'),
                        subtitle: Text('\$${order.totalAmount.toStringAsFixed(2)} - ${order.status}'),
                        trailing: canTrack
                            ? FilledButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id))),
                                child: const Text('Track'),
                              )
                            : null,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ordered on: ${order.createdAt.toString().split('.')[0]}'),
                                const SizedBox(height: 8),
                                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...order.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${item.name} x${item.quantity}'),
                                      Text('\$${item.price.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'processing': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Icons.check;
      case 'shipped': return Icons.local_shipping;
      case 'processing': return Icons.hourglass_empty;
      case 'cancelled': return Icons.cancel;
      default: return Icons.receipt;
    }
  }
}