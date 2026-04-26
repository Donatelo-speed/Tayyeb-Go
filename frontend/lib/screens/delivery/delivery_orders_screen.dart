import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _myOrders = [];
  bool _isLoading = true;
  bool _isOnline = false;
  String _currentTab = 'queue';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final driversResult = await ApiEndpoints.get('/delivery/my-orders', token: token);
      final statusResult = await ApiEndpoints.get('/delivery/status', token: token);
      
      if (mounted) {
        setState(() {
          _orders = driversResult['available_orders'] ?? [];
          _myOrders = driversResult['my_orders'] ?? [];
          _isOnline = statusResult['is_online'] ?? false;
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
        _orders = [
          {
            'id': 101,
            'customer_name': 'John Smith',
            'customer_phone': '555-1234',
            'shipping_address': '123 Main St, New York, NY 10001',
            'items': [
              {'name': 'Wireless Headphones', 'quantity': 2, 'price': '59.98'},
              {'name': 'Phone Case', 'quantity': 1, 'price': '15.99'},
            ],
            'total_amount': '75.97',
            'payment_status': 'paid',
            'notes': 'Leave at door',
          },
          {
            'id': 102,
            'customer_name': 'Jane Doe',
            'customer_phone': '555-5678',
            'shipping_address': '456 Oak Ave, Brooklyn, NY 11201',
            'items': [
              {'name': 'Smart Watch', 'quantity': 1, 'price': '149.99'},
            ],
            'total_amount': '149.99',
            'payment_status': 'cod',
            'notes': 'Call before arrival',
          },
          {
            'id': 103,
            'customer_name': 'Bob Wilson',
            'customer_phone': '555-9012',
            'shipping_address': '789 Pine Rd, Queens, NY 11375',
            'items': [
              {'name': 'Laptop Stand', 'quantity': 1, 'price': '39.99'},
              {'name': 'USB Hub', 'quantity': 2, 'price': '25.98'},
            ],
            'total_amount': '65.97',
            'payment_status': 'paid',
            'notes': '',
          },
        ];
        _myOrders = [
          {
            'id': 99,
            'customer_name': 'Alice Brown',
            'customer_phone': '555-1111',
            'shipping_address': '321 Elm St, Bronx, NY 10451',
            'items': [
              {'name': 'Bluetooth Speaker', 'quantity': 1, 'price': '79.99'},
            ],
            'total_amount': '79.99',
            'payment_status': 'paid',
            'status': 'picked_up',
            'notes': 'Gift wrapping',
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery App'),
        actions: [
          _buildDutyToggle(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusBar(),
                Expanded(
                  child: _currentTab == 'queue'
                      ? _buildOrderQueue()
                      : _currentTab == 'active'
                          ? _buildActiveTask()
                          : _buildHistory(),
                ),
              ],
            ),
    );
  }

  Widget _buildDutyToggle() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isOnline ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: _isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          Switch(
            value: _isOnline,
            onChanged: (value) async {
              await ApiEndpoints.post('/delivery/toggle-status', {'is_online': value}, token: Provider.of<AuthProvider>(context, listen: false).token);
              setState(() => _isOnline = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatusButton(label: 'Order Queue', icon: Icons.list, isSelected: _currentTab == 'queue', onTap: () => setState(() => _currentTab = 'queue')),
          _StatusButton(label: 'Current Task', icon: Icons.local_shipping, isSelected: _currentTab == 'active', onTap: () => setState(() => _currentTab = 'active'), badge: _myOrders.isNotEmpty ? _myOrders.length : null),
          _StatusButton(label: 'History', icon: Icons.history, isSelected: _currentTab == 'history', onTap: () => setState(() => _currentTab = 'history')),
        ],
      ),
    );
  }

  Widget _buildOrderQueue() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No orders available'),
            const SizedBox(height: 8),
            Text('Go online to receive orders', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _OrderCard(
          order: order,
          onAccept: () => _acceptOrder(order),
          onDetails: () => _showInvoice(order),
        );
      },
    );
  }

  Widget _buildActiveTask() {
    if (_myOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No active delivery'),
            const SizedBox(height: 8),
            Text('Accept orders from the queue', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final order = _myOrders.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Order #${order['id']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Chip(label: Text(order['status'].toString().toUpperCase())),
                    ],
                  ),
                  const Divider(),
                  const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.person), const SizedBox(width: 8), Text(order['customer_name'])]),
                  Row(children: [const Icon(Icons.phone), const SizedBox(width: 8), Text(order['customer_phone'])]),
                  Row(children: [const Icon(Icons.location_on), const SizedBox(width: 8), Expanded(child: Text(order['shipping_address']))]),
                  if (order['notes'] != null && order['notes'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [const Icon(Icons.note), const SizedBox(width: 8), Text('Note: ${order['notes']}', style: TextStyle(fontStyle: FontStyle.italic))]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...(order['items'] as List).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['name']} x${item['quantity']}'),
                        Text('\$${item['price']}'),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Chip(label: Text('Payment: ${order['payment_status']}'.toUpperCase()), backgroundColor: order['payment_status'] == 'paid' ? Colors.green[100] : Colors.orange[100]),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  onPressed: () => _callCustomer(order['customer_phone']),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                  onPressed: () => _navigateToAddress(order['shipping_address']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (order['status'] == 'picked_up')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Delivered'),
                onPressed: () => _completeDelivery(order['id']),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.inventory),
                label: const Text('Confirm Pickup'),
                onPressed: () => _confirmPickup(order['id']),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Completed Deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.check, color: Colors.green)),
          title: const Text('Order #95'),
          subtitle: const Text('Delivered - Jan 15, 2025'),
          trailing: const Text('\$89.99'),
        ),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.check, color: Colors.green)),
          title: const Text('Order #87'),
          subtitle: const Text('Delivered - Jan 14, 2025'),
          trailing: const Text('\$125.00'),
        ),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.check, color: Colors.green)),
          title: const Text('Order #82'),
          subtitle: const Text('Delivered - Jan 13, 2025'),
          trailing: const Text('\$45.99'),
        ),
      ],
    );
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Order #${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order['customer_name']}'),
            Text('Total: \$${order['total_amount']}'),
            Text('Address: ${order['shipping_address']}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Accept')),
        ],
      ),
    );

    if (confirm == true) {
      await ApiEndpoints.post('/delivery/accept', {'order_id': order['id']}, token: Provider.of<AuthProvider>(context, listen: false).token);
      _loadData();
    }
  }

  void _showInvoice(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('INVOICE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('#${order['id']}', style: const TextStyle(fontSize: 24)),
                ],
              ),
              const Divider(),
              const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Customer: ${order['customer_name']}'),
              Text('Phone: ${order['customer_phone']}'),
              Text('Address: ${order['shipping_address']}'),
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(order['items'] as List).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['name']} x${item['quantity']}'),
                    Text('\$${item['price']}'),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('\$${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(label: Text('Payment: ${order['payment_status']}'.toUpperCase())),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print Invoice'),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _navigateToAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmPickup(int orderId) async {
    await ApiEndpoints.put('/delivery/orders/$orderId', {'status': 'picked_up'}, token: Provider.of<AuthProvider>(context, listen: false).token);
    _loadData();
  }

  Future<void> _completeDelivery(int orderId) async {
    await ApiEndpoints.put('/delivery/orders/$orderId', {'status': 'delivered'}, token: Provider.of<AuthProvider>(context, listen: false).token);
    _loadData();
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _StatusButton({required this.label, required this.icon, required this.isSelected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: badge != null
            ? Badge(label: Text('$badge'), child: _buildContent())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onDetails;

  const _OrderCard({required this.order, required this.onAccept, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(label: Text('\$${order['total_amount']}'), padding: EdgeInsets.zero),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.person, size: 16), const SizedBox(width: 4), Text(order['customer_name'])]),
            Row(children: [const Icon(Icons.location_on, size: 16), const SizedBox(width: 4), Expanded(child: Text(order['shipping_address'], maxLines: 2, overflow: TextOverflow.ellipsis))]),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(order['payment_status']), backgroundColor: order['payment_status'] == 'paid' ? Colors.green[100] : Colors.orange[100]),
                const Spacer(),
                TextButton.icon(icon: const Icon(Icons.receipt), onPressed: onDetails, label: const Text('Invoice')),
                FilledButton.icon(icon: const Icon(Icons.check), onPressed: onAccept, label: const Text('Accept')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}