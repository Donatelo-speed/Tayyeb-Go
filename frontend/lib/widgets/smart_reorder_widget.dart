import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class SmartReorderWidget extends StatelessWidget {
  const SmartReorderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Demo frequently ordered items
    final frequentItems = [
      {'id': 1, 'name': 'Fresh Milk 1L', 'price': 5.99, 'image': 'https://via.placeholder.com/100?text=Milk', 'orderCount': 12},
      {'id': 2, 'name': 'Eggs 12pcs', 'price': 6.99, 'image': 'https://via.placeholder.com/100?text=Eggs', 'orderCount': 10},
      {'id': 3, 'name': 'Arabic Bread', 'price': 4.99, 'image': 'https://via.placeholder.com/100?text=Bread', 'orderCount': 8},
      {'id': 4, 'name': 'Chicken Breast', 'price': 24.99, 'image': 'https://via.placeholder.com/100?text=Chicken', 'orderCount': 6},
    ];

    if (frequentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.autorenew, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buy It Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Based on your order history', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal scrollable list
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: frequentItems.length,
              itemBuilder: (context, index) {
                final item = frequentItems[index];
                return _ReorderItemCard(
                  item: item,
                  isDark: isDark,
                  onAddToCart: () {
                    // Add to cart
                    final product = Product(
                      id: item['id'],
                      name: item['name'],
                      description: '',
                      price: item['price'],
                      category: 'Frequent',
                      stockQuantity: 100,
                    );
                    context.read<CartProvider>().addToCart(product);
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item['name']} added to cart'),
                        action: SnackBarAction(
                          label: 'View Cart',
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 1-Click Reorder Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showOneClickReorder(context, frequentItems),
              icon: const Icon(Icons.flash_on),
              label: const Text('1-Click Reorder All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOneClickReorder(BuildContext context, List<Map<String, dynamic>> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double total = items.fold(0, (sum, item) => sum + (item['price'] as double));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Quick Reorder', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),

            // Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(item['image']),
                    ),
                    title: Text(item['name']),
                    subtitle: Text('Ordered ${item['orderCount']} times'),
                    trailing: Text('SAR ${item['price']}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        Text('Total (${items.length} items)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('SAR ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
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
                        child: const Text('Place Order Now', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _ReorderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final VoidCallback onAddToCart;

  const _ReorderItemCard({
    required this.item,
    required this.isDark,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CachedNetworkImage(
                imageUrl: item['image'],
                fit: BoxFit.cover,
                placeholder: (_, __) => const Icon(Icons.image),
                errorWidget: (_, __, ___) => const Icon(Icons.shopping_bag),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            item['name'],
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          // Price and Add button
          Row(
            children: [
              Text(
                'SAR ${item['price']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}