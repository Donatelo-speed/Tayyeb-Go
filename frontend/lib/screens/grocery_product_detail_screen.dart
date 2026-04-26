import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';

class GroceryProductDetailScreen extends StatefulWidget {
  final Product product;
  
  const GroceryProductDetailScreen({super.key, required this.product});

  @override
  State<GroceryProductDetailScreen> createState() => _GroceryProductDetailScreenState();
}

class _GroceryProductDetailScreenState extends State<GroceryProductDetailScreen> {
  int _quantity = 1;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black54 : Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black54 : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    wishlist.isInWishlist(product.id) ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => wishlist.toggleWishlist(product),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black54 : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey[200],
                    child: product.imageUrls?.isNotEmpty == true
                        ? CachedNetworkImage(imageUrl: product.mainImageUrl, fit: BoxFit.cover)
                        : const Icon(Icons.shopping_basket, size: 100, color: Colors.grey),
                  ),
                  // Discount Badge
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('-20%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price and Unit
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ ${product.unit ?? 'pc'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stock Status
                  Row(
                    children: [
                      Icon(
                        product.stockQuantity > 0 ? Icons.check_circle : Icons.cancel,
                        color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.stockQuantity > 0 ? 'In Stock (${product.stockQuantity} available)' : 'Out of Stock',
                        style: TextStyle(color: product.stockQuantity > 0 ? Colors.green : Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nutritional Info (for food)
                  _NutritionalInfo(),
                  const SizedBox(height: 24),
                  
                  // Reviews Section
                  _ReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Bar with Add to Cart
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252542) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Add to Cart Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: product.stockQuantity > 0
                      ? () {
                          cart.addToCart(product, quantity: _quantity);
                          _showAddedToCartDialog();
                        }
                      : null,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text('Add to Cart - \$${(product.price * _quantity).toStringAsFixed(2)}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddedToCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Added!'),
          ],
        ),
        content: Text('$_quantity ${widget.product.name} added to cart'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Shopping')),
          FilledButton(onPressed: () => Navigator.pop(context, Navigator.pop(context)), child: const Text('View Cart')),
        ],
      ),
    );
  }
}

class _NutritionalInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutritional Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutrientItem(label: 'Energy', value: '250 kcal'),
              _NutrientItem(label: 'Protein', value: '5g'),
              _NutrientItem(label: 'Fat', value: '10g'),
              _NutrientItem(label: 'Carbs', value: '30g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientItem extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('See All')),
          ],
        ),
        const SizedBox(height: 8),
        // Average Rating
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const Icon(Icons.star_half, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text('4.5 (128 reviews)', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 16),
        // Sample Review
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 16, child: Text('A')),
                  const SizedBox(width: 8),
                  const Text('Ahmed K.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Row(
                    children: List.generate(5, (i) => Icon(Icons.star, color: Colors.amber, size: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Great quality, fresh products! Very satisfied with the delivery.'),
            ],
          ),
        ),
      ],
    );
  }
}