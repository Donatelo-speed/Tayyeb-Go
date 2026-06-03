import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/shimmer_loading.dart';
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
      backgroundColor: TayyebGoColors.background,
      appBar: AppBar(
        title: Text(widget.categoryFilter ?? 'All Products'),
        surfaceTintColor: Colors.transparent,
        backgroundColor: TayyebGoColors.surface,
        actions: [
          IconButton(
            icon: Icon(_gridView ? Icons.grid_view_rounded : Icons.view_list_rounded),
            onPressed: () => setState(() => _gridView = !_gridView),
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
            return _buildList(_fallbackProducts(), cart);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => SkeletonCard(height: 160),
            );
          }
          final products = snapshot.data!.docs
              .map((doc) => Product.fromJson(
                  {'id': doc.id, ...doc.data() as Map<String, dynamic>}))
              .toList();
          if (products.isEmpty) return _buildList(_fallbackProducts(), cart);
          return _buildList(products, cart);
        },
      ),
    );
  }

  List<Product> _fallbackProducts() => [
        Product(
            id: 1,
            name: 'Margherita Pizza',
            price: 12.99,
            stockQuantity: 100,
            category: 'Pizza',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Pizza'
            ]),
        Product(
            id: 2,
            name: 'Chicken Burger',
            price: 9.99,
            stockQuantity: 100,
            category: 'Fast Food',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Burger'
            ]),
        Product(
            id: 3,
            name: 'Caesar Salad',
            price: 8.49,
            stockQuantity: 100,
            category: 'Salads',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Salad'
            ]),
        Product(
            id: 4,
            name: 'Chocolate Cake',
            price: 6.99,
            stockQuantity: 100,
            category: 'Desserts',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Cake'
            ]),
      ];

  Widget _buildList(List<Product> products, CartProvider cart) {
    if (_gridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => _ProductGridCard(
          product: products[i],
          onAdd: () {
            cart.addLine(products[i]);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${products[i].displayName} added'),
                backgroundColor: TayyebGoColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductListCard(
        product: products[i],
        onAdd: () {
          cart.addLine(products[i]);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${products[i].displayName} added'),
              backgroundColor: TayyebGoColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  const _ProductGridCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.imageUrls != null && product.imageUrls!.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ProductDetailScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: TayyebGoColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: TayyebGoColors.divider.withValues(alpha: 0.4)),
          boxShadow: TayyebGoTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image:
                              NetworkImage(product.imageUrls!.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: hasImage
                      ? null
                      : LinearGradient(
                          colors: [
                            TayyebGoGradients.hero.colors[0]
                                .withValues(alpha: 0.12),
                            TayyebGoGradients.hero.colors[1]
                                .withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Stack(
                  children: [
                    if (!hasImage)
                      Center(
                        child: Icon(Icons.restaurant_rounded,
                            size: 40,
                            color: TayyebGoColors.primary
                                .withValues(alpha: 0.12)),
                      ),
                    if (product.isSpicy)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: TayyebGoColors.error,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons
                                  .local_fire_department_rounded,
                              size: 14,
                              color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black
                                  .withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                        product.category ?? 'Food',
                        style: const TextStyle(
                            fontSize: 11,
                            color:
                                TayyebGoColors.textMuted)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color:
                                    TayyebGoColors.primary)),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient:
                                  TayyebGoGradients.hero,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TayyebGoColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: TayyebGoColors.divider.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    TayyebGoColors.primary
                        .withValues(alpha: 0.12),
                    TayyebGoColors.primary
                        .withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Icon(Icons.restaurant_rounded,
                  size: 36,
                  color: TayyebGoColors.primary
                      .withValues(alpha: 0.2)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                      product.description ??
                          'Delicious food',
                      style: const TextStyle(
                          color: TayyebGoColors.textSecondary,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color:
                                  TayyebGoColors.primary)),
                      ElevatedButton(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              TayyebGoColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
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

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen(
      {super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: TayyebGoColors.background,
      appBar: AppBar(
        title: Text(product.displayName),
        backgroundColor: TayyebGoColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TayyebGoColors.primary
                        .withValues(alpha: 0.08),
                    TayyebGoColors.primary
                        .withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Icon(Icons.restaurant_rounded,
                    size: 80,
                    color: TayyebGoColors.primary
                        .withValues(alpha: 0.15)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(product.displayName,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                      ),
                      Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color:
                                  TayyebGoColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (product.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: TayyebGoColors.primary
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(product.category!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  TayyebGoColors.primary)),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    product.description ??
                        'A delicious ${product.displayName} prepared with the finest ingredients.',
                    style: const TextStyle(
                        fontSize: 15,
                        color:
                            TayyebGoColors.textSecondary,
                        height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        cart.addLine(product);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Added to cart!'),
                            backgroundColor:
                                TayyebGoColors.success,
                            behavior:
                                SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            TayyebGoColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor:
                            TayyebGoColors.primary
                                .withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Add to Cart',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
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