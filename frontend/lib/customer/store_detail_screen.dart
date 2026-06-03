import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import '../theme/tayyebgo_theme.dart';
import '../models/vendor.dart';
import '../models/product.dart';

class StoreDetailScreen extends StatefulWidget {
  final Vendor vendor;
  const StoreDetailScreen({super.key, required this.vendor});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.red];
    final color = colors[int.parse(widget.vendor.id) % colors.length];
    final cart = context.read<CartProvider>();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.vendor.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.store, color: Colors.white, size: 35),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Menu'),
                Tab(text: 'Info'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMenuTab(color, cart),
            _buildInfoTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab(Color color, CartProvider cart) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: widget.vendor.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildFallbackMenu(color, cart);
        }
        final products = snapshot.data!.docs.map((doc) {
          return Product.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>});
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductItem(color, product, cart);
          },
        );
      },
    );
  }

  Widget _buildFallbackMenu(Color color, CartProvider cart) {
    final fallback = [
      Product(id: 1, name: 'Special Dish', price: 14.99, stockQuantity: 100, description: 'Chef special'),
      Product(id: 2, name: 'Family Meal', price: 29.99, stockQuantity: 100, description: 'Serves 4'),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: fallback.length,
      itemBuilder: (context, index) => _buildProductItem(color, fallback[index], cart),
    );
  }

  Widget _buildProductItem(Color color, Product product, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TayyebGoTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.fastfood, color: color, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(product.description ?? 'Delicious',
                    style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                    ElevatedButton(
                      onPressed: () {
                        cart.addLine(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added ${product.displayName}')));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
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

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.store, label: 'Type', value: widget.vendor.typeDisplay),
          _InfoRow(icon: Icons.location_on, label: 'Address', value: widget.vendor.address),
          _InfoRow(icon: Icons.star, label: 'Rating', value: widget.vendor.rating.toStringAsFixed(1)),
          _InfoRow(icon: Icons.access_time, label: 'Status', value: widget.vendor.isOpen ? 'Open' : 'Closed'),
          if (widget.vendor.phone != null)
            _InfoRow(icon: Icons.phone, label: 'Phone', value: widget.vendor.phone!),
          if (widget.vendor.email != null)
            _InfoRow(icon: Icons.email, label: 'Email', value: widget.vendor.email!),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 60, color: Colors.amber),
          const SizedBox(height: 16),
          Text('${widget.vendor.rating.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${(widget.vendor.rating * 10).toInt()} reviews',
              style: TextStyle(color: TayyebGoTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () {}, child: const Text('Write a Review')),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TayyebGoTheme.textMuted),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: TayyebGoTheme.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
