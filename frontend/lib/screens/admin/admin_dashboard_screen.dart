import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _deliveryDrivers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      final statsResult = await ApiEndpoints.get('/admin/stats', token: token);
      final productsResult = await ApiEndpoints.get('/admin/products', token: token);
      final usersResult = await ApiEndpoints.get('/admin/users', token: token);
      final ordersResult = await ApiEndpoints.get('/admin/orders', token: token);
      final driversResult = await ApiEndpoints.get('/admin/delivery-drivers', token: token);

      if (mounted) {
        setState(() {
          _stats = statsResult['stats'];
          _products = productsResult['products'] ?? [];
          _users = usersResult['users'] ?? [];
          _orders = ordersResult['orders'] ?? [];
          _deliveryDrivers = driversResult['drivers'] ?? [];
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
        _stats = {'totalProducts': 5000, 'totalUsers': 1250, 'totalOrders': 3420, 'revenue': 125000.00, 'activeDrivers': 15, 'pendingDrivers': 3};
        _products = List.generate(50, (i) => {'id': i + 1, 'name': 'Product ${i + 1}', 'price': (9.99 + i * 2).toStringAsFixed(2), 'stock_quantity': (i * 7 % 100) + 10, 'category': _demoCategories[i % _demoCategories.length]});
        _users = [
          {'id': 1, 'email': 'admin@omni.com', 'name': 'Admin User', 'role': 'admin', 'status': 'active'},
          {'id': 2, 'email': 'driver1@test.com', 'name': 'John Driver', 'role': 'delivery', 'status': 'pending', 'phone': '555-0101'},
          {'id': 3, 'email': 'driver2@test.com', 'name': 'Jane Driver', 'role': 'delivery', 'status': 'active', 'phone': '555-0102', 'current_location': {'lat': 40.7128, 'lng': -74.0060}},
          {'id': 4, 'email': 'user@test.com', 'name': 'Test User', 'role': 'customer', 'status': 'active', 'phone': '555-0103'},
        ];
        _orders = [
          {'id': 1, 'user_name': 'Test User', 'total_amount': '59.99', 'status': 'processing', 'created_at': DateTime.now().toIso8601String()},
          {'id': 2, 'user_name': 'Test User', 'total_amount': '89.97', 'status': 'shipped', 'assigned_driver_id': 3, 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
          {'id': 3, 'user_name': 'Test User', 'total_amount': '125.00', 'status': 'delivered', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        ];
        _deliveryDrivers = [
          {'id': 2, 'name': 'John Driver', 'phone': '555-0101', 'status': 'pending'},
          {'id': 3, 'name': 'Jane Driver', 'phone': '555-0102', 'status': 'active', 'current_location': {'lat': 40.7128, 'lng': -74.0060}},
          {'id': 4, 'name': 'Mike Driver', 'phone': '555-0103', 'status': 'active', 'current_location': {'lat': 40.7580, 'lng': -73.9855}},
        ];
        _isLoading = false;
      });
    }
  }

  static final List<String> _demoCategories = ['Electronics', 'Accessories', 'Audio', 'Storage', 'Office', 'Gaming', 'Mobile', 'Computing', 'Smart Home', 'Wearables', 'Photography'];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<Map<String, dynamic>> get _pendingDrivers {
    return _deliveryDrivers.where((d) => d['status'] == 'pending').toList();
  }

  List<Map<String, dynamic>> get _activeDrivers {
    return _deliveryDrivers.where((d) => d['status'] == 'active').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
            Tab(icon: Icon(Icons.map), text: 'Live Map'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Drivers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(),
                _buildProducts(),
                _buildLiveMap(),
                _buildUsers(),
                _buildDrivers(),
              ],
            ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatCard(title: 'Total Revenue', value: '\$${((_stats?['revenue'] ?? 0) as num).toStringAsFixed(2)}', icon: Icons.attach_money, color: Colors.green),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Total Orders', value: '${_stats?['totalOrders'] ?? 0}', icon: Icons.receipt, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Customers', value: '${_stats?['totalUsers'] ?? 0}', icon: Icons.people, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Products', value: '${_stats?['totalProducts'] ?? 0}', icon: Icons.inventory, color: Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Active Drivers', value: '${_stats?['activeDrivers'] ?? 0}', icon: Icons.local_shipping, color: Colors.teal)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...(_orders.take(5).map((o) => ListTile(
            leading: CircleAvatar(backgroundColor: _getStatusColor(o['status']), child: Icon(_getStatusIcon(o['status']), color: Colors.white, size: 16)),
            title: Text('Order #${o['id']}'),
            subtitle: Text('\$${o['total_amount']} - ${o['user_name']}'),
          ))),
          const SizedBox(height: 24),
          const Text('Pending Driver Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_pendingDrivers.isEmpty)
            const Text('No pending drivers')
          else
            ...(_pendingDrivers.map((d) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(d['name']),
            subtitle: Text(d['email']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _approveDriver(d['id'])),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _rejectDriver(d['id'])),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildProducts() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.inventory)),
                title: Text(product['name']),
                subtitle: Text('Stock: ${product['stock_quantity']} | \$${product['price']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _editProduct(product)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteProduct(product['id'])),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMap() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _StatCard(title: 'Active Drivers', value: '${_activeDrivers.length}', icon: Icons.local_shipping, color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Pending Deliveries', value: '${_orders.where((o) => o['status'] == 'processing').length}', icon: Icons.hourglass_empty, color: Colors.orange)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Live Map View', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('Add Google Maps API Key to enable', style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                ),
                ...(_activeDrivers.map((driver) => Positioned(
                  left: 100.0 + (driver['id'] * 30) % 200,
                  top: 100.0 + (driver['id'] * 40) % 150,
                  child: GestureDetector(
                    onTap: () => _showDriverDetails(driver),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
                    ),
                  ),
                ))),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Real-time driver locations (WebSocket required for live updates)', style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _buildUsers() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          leading: CircleAvatar(child: Text(user['name'][0])),
          title: Text(user['name']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['email']),
              if (user['phone'] != null) Text(user['phone'], style: const TextStyle(fontSize: 12)),
            ],
          ),
          isThreeLine: user['phone'] != null,
          trailing: PopupMenuButton<String>(
            onSelected: (status) => _updateUserStatus(user['id'], status),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'active', child: Text('Activate')),
              const PopupMenuItem(value: 'inactive', child: Text('Deactivate')),
              const PopupMenuItem(value: 'suspended', child: Text('Suspend')),
            ],
          ),
          onTap: () => _showUserDetails(user),
        );
      },
    );
  }

  Widget _buildDrivers() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Pending Interviews'), Tab(text: 'Active Drivers')]),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: _pendingDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = _pendingDrivers[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [const Icon(Icons.person), const SizedBox(width: 8), Text(driver['name'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 8),
                            Text('Phone: ${driver['phone']}'),
                            Text('Email: ${driver['email']}'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _rejectDriver(driver['id']), label: const Text('Reject'))),
                                const SizedBox(width: 8),
                                Expanded(child: FilledButton.icon(icon: const Icon(Icons.check), onPressed: () => _approveDriver(driver['id']), label: const Text('Approve'))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ListView.builder(
                  itemCount: _activeDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = _activeDrivers[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.green, child: const Icon(Icons.local_shipping, color: Colors.white)),
                      title: Text(driver['name']),
                      subtitle: Text('Location: ${driver['current_location'] ?? 'Unknown'}'),
                      trailing: IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
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

  void _editProduct(Map<String, dynamic> product) {
    final priceController = TextEditingController(text: product['price']);
    final stockController = TextEditingController(text: product['stock_quantity'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => _updateProduct(product['id'], priceController.text, stockController.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _updateProduct(int id, String price, String stock) async {
    await ApiEndpoints.put('/admin/products/$id', {'price': price, 'stock_quantity': stock}, token: Provider.of<AuthProvider>(context, listen: false).token);
    if (mounted) Navigator.pop(context);
    _loadData();
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete Product'), content: const Text('Are you sure?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (confirm == true) {
      await ApiEndpoints.delete('/admin/products/$id', token: Provider.of<AuthProvider>(context, listen: false).token);
      _loadData();
    }
  }

  Future<void> _approveDriver(int id) async {
    await ApiEndpoints.put('/admin/drivers/$id', {'status': 'active'}, token: Provider.of<AuthProvider>(context, listen: false).token);
    _loadData();
  }

  Future<void> _rejectDriver(int id) async {
    await ApiEndpoints.put('/admin/drivers/$id', {'status': 'rejected'}, token: Provider.of<AuthProvider>(context, listen: false).token);
    _loadData();
  }

  Future<void> _updateUserStatus(int userId, String status) async {
    await ApiEndpoints.put('/admin/users/$userId', {'status': status}, token: Provider.of<AuthProvider>(context, listen: false).token);
    _loadData();
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(context: context, builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Email: ${user['email']}'),
          if (user['phone'] != null) Text('Phone: ${user['phone']}'),
          Text('Role: ${user['role']}'),
          Text('Status: ${user['status']}'),
        ],
      ),
    ));
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showModalBottomSheet(context: context, builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(driver['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Current Location: ${driver['current_location']}'),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.phone), onPressed: () {}, label: const Text('Call'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(icon: const Icon(Icons.message), onPressed: () {}, label: const Text('Message'))),
            ],
          ),
        ],
      ),
    ));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'processing': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered': return Icons.check;
      case 'shipped': return Icons.local_shipping;
      case 'processing': return Icons.hourglass_empty;
      case 'cancelled': return Icons.cancel;
      default: return Icons.receipt;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}