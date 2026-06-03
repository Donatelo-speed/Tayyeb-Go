import 'package:flutter/material.dart';
import 'dart:async';

class KitchenTabletScreen extends StatefulWidget {
  const KitchenTabletScreen({super.key});

  @override
  State<KitchenTabletScreen> createState() => _KitchenTabletScreenState();
}

class _KitchenTabletScreenState extends State<KitchenTabletScreen> {
  Timer? _refreshTimer;
  
  List<KitchenOrder> _orders = [
    KitchenOrder(
      id: 'ORD-001',
      customerName: 'Ahmed K.',
      customerPhone: '+963912345678',
      items: [
        OrderItem(name: 'Shawarma Mix', quantity: 2, modifiers: 'Extra garlic'),
        OrderItem(name: 'Fries', quantity: 1, modifiers: ''),
      ],
      total: 8500,
      deliveryType: DeliveryType.delivery,
      timeElapsed: const Duration(minutes: 3),
    ),
    KitchenOrder(
      id: 'ORD-002',
      customerName: 'Sarah M.',
      customerPhone: '+963912345679',
      items: [
        OrderItem(name: 'Burger Classic', quantity: 1, modifiers: 'No onions'),
        OrderItem(name: 'Cola', quantity: 2, modifiers: ''),
      ],
      total: 6500,
      deliveryType: DeliveryType.pickup,
      timeElapsed: const Duration(minutes: 1),
    ),
    KitchenOrder(
      id: 'ORD-003',
      customerName: 'Omar R.',
      customerPhone: '+963912345680',
      items: [
        OrderItem(name: 'Pizza Margherita', quantity: 1, modifiers: 'Large, thin crust'),
        OrderItem(name: 'Garlic Bread', quantity: 1, modifiers: ''),
      ],
      total: 9500,
      deliveryType: DeliveryType.delivery,
      timeElapsed: const Duration(minutes: 8),
    ),
];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Refresh orders from API
      setState(() {
        // Update time elapsed
        _orders = _orders.map((order) {
          return KitchenOrder(
            id: order.id,
            customerName: order.customerName,
            customerPhone: order.customerPhone,
            items: order.items,
            total: order.total,
            deliveryType: order.deliveryType,
            timeElapsed: order.timeElapsed + const Duration(seconds: 30),
          );
        }).toList();
      });
    });
  }

  void _acknowledgeOrder(String orderId) {
    setState(() {
      _orders = _orders.where((o) => o.id != orderId).toList();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16A085),
        title: const Row(
          children: [
            Icon(Icons.restaurant, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Kitchen Display',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${_orders.length} Active',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Pending Orders',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All caught up! 🎉',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _OrderCard(
                  order: order,
                  onAcknowledge: () => _acknowledgeOrder(order.id),
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback onAcknowledge;

  const _OrderCard({
    required this.order,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = order.timeElapsed.inMinutes > 5;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent 
            ? Border.all(color: Colors.red, width: 3) 
            : null,
        boxShadow: [
          BoxShadow(
            color: isUrgent 
                ? Colors.red.withValues(alpha: 0.3) 
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: order.deliveryType == DeliveryType.delivery
                  ? const Color(0xFF16A085)
                  : Colors.orange,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      order.deliveryType == DeliveryType.delivery
                          ? Icons.delivery_dining
                          : Icons.storefront,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.deliveryType == DeliveryType.delivery 
                          ? 'Delivery' 
                          : 'Pickup',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Customer Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      order.customerPhone,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A085).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A085),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (item.modifiers.isNotEmpty)
                              Text(
                                item.modifiers,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: isUrgent ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${order.timeElapsed.inMinutes}m',
                          style: TextStyle(
                            color: isUrgent ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${order.total} SYP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 120,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onAcknowledge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A085),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ACK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DATA MODELS
// =====================================================

enum DeliveryType { delivery, pickup }

class KitchenOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final int total;
  final DeliveryType deliveryType;
  final Duration timeElapsed;

  KitchenOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.deliveryType,
    required this.timeElapsed,
  });
}

class OrderItem {
  final String name;
  final int quantity;
  final String modifiers;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.modifiers,
  });
}