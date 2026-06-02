import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import '../theme/tayyebgo_theme.dart';
import '../models/product.dart';

class CatalogScreen extends StatefulWidget {
  final String? categoryFilter;
  const CatalogScreen({super.key, this.categoryFilter});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: Icon(_gridView ? Icons.grid_view : Icons.list),
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Text('Newest')),
              const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.categoryFilter != null
            ? FirebaseFirestore.instance
                .collection('products')
                .where('category', isEqualTo: widget.categoryFilter)
                .snapshots()
            : FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildFallbackList(cart);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!.docs.map((doc) {
            return Product.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>});
          }).toList();
          if (products.isEmpty) return _buildFallbackList(cart);
          return _buildProductList(products, cart);
        },
      ),
    );
  }

  Widget _buildFallbackList(CartProvider cart) {
    final fallback = [
      Product(id: 1, name: 'Margherita Pizza', price: 12.99, stockQuantity: 100, description: 'Classic cheese pizza'),
      Product(id: 2, name: 'Chicken Burger', price: 9.99, stockQuantity: 100, description: 'Grilled chicken burger'),
      Product(id: 3, name: 'Caesar Salad', price: 8.49, stockQuantity: 100, description: 'Fresh Caesar salad'),
      Product(id: 4, name: 'Chocolate Cake', price: 6.99, stockQuantity: 100, description: 'Rich chocolate cake'),
    ];
    return _buildProductList(fallback, cart);
  }

  Widget _buildProductList(List<Product> products, CartProvider cart) {
    if (_gridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductGridCard(
            product: product,
            onAdd: () {
              cart.addLine(product);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${product.displayName}')));
            },
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductListCard(
          product: product,
          onAdd: () {
            cart.addLine(product);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${product.displayName}')));
          },
        );
      },
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  const _ProductGridCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: TayyebGoTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: TayyebGoTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(child: Icon(Icons.fastfood, size: 50, color: TayyebGoTheme.primaryColor)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.displayName, style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(color: TayyebGoTheme.primaryColor,
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: TayyebGoTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
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

class _ProductListCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  const _ProductListCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TayyebGoTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: TayyebGoTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood, size: 40, color: TayyebGoTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(product.description ?? 'Delicious food',
                    style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: TayyebGoTheme.primaryColor,
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TayyebGoTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(product.displayName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: TayyebGoTheme.primaryColor.withOpacity(0.1),
              child: const Center(child: Icon(Icons.fastfood, size: 80, color: TayyebGoTheme.primaryColor)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                          color: TayyebGoTheme.primaryColor)),
                  const SizedBox(height: 16),
                  Text(product.description ?? 'Delicious food',
                      style: TextStyle(color: TayyebGoTheme.textSecondary, height: 1.5)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        cart.addLine(product);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart!')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TayyebGoTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Add to Cart',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
