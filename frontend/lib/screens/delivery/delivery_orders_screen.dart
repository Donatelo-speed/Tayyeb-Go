import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/omni_theme.dart';
import '../../main.dart';
import '../login_screen.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isOnline = false;
  List<dynamic> _orders = [];
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _loadOrders();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final data = await _api.getDeliveryOrders();
        _orders = data['orders'] ?? [];
      }
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final auth = context.watch<AuthProvider>();
    final isArabic = locale.isArabic;

    String t(String en, String ar) => isArabic ? ar : en;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(t('Delivery', 'التوصيل'))),
        body: Center(child: CircularProgressIndicator(color: OmniTheme.primaryColor)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(Icons.two_wheeler, size: 26),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(t('Delivery', 'التوصيل')),
          ],
        ),
        backgroundColor: OmniTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(_isOnline ? t('Online', 'متصل') : t('Offline', 'غير متصل'), style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Switch(
                  value: _isOnline,
                  onChanged: (v) => setState(() => _isOnline = v),
                  activeColor: Colors.lightGreenAccent,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(Icons.delivery_dining, size: 80, color: Colors.grey[300]),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(t('No orders available', 'لا توجد طلبات'), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(t('Stay online to receive orders', 'ابقَ متصلاً لتلقي الطلبات'), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(_orders[index]);
                },
              ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final locale = context.read<LocaleBox>();
    final isArabic = locale.isArabic;

    String t(String en, String ar) => isArabic ? ar : en;

    String status = order['status'] ?? 'pending';
    Color statusColor;
    if (status == 'pending') statusColor = Colors.orange;
    else if (status == 'accepted') statusColor = Colors.blue;
    else if (status == 'delivered') statusColor = Colors.green;
    else statusColor = Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order['id'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(status, style: TextStyle(color: statusColor)),
                  backgroundColor: statusColor.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('\$${order['total'] ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: OmniTheme.primaryColor)),
            const SizedBox(height: 8),
            Text(order['delivery_address'] ?? '', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            if (status == 'pending')
              ElevatedButton.icon(
                onPressed: () => _acceptOrder(order['id']),
                icon: const Icon(Icons.check),
                label: Text(t('Accept', 'قبول')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(dynamic orderId) async {
    try {
      int id = int.parse(orderId.toString());
      await _api.acceptOrder(id);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}