import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.grey[200],
                child: product.imageUrls?.isNotEmpty == true
                    ? Image.network(product.mainImageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 64))
                    : const Icon(Icons.image, size: 64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  if (product.brand != null) Text('Brand: ${product.brand}', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Text('\$${product.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(product.inStock ? Icons.check_circle : Icons.cancel, color: product.inStock ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(product.inStock ? 'In Stock (${product.stockQuantity})' : 'Out of Stock', style: TextStyle(color: product.inStock ? Colors.green : Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (product.category.isNotEmpty) Chip(label: Text(product.category)),
                  const SizedBox(height: 16),
                  if (product.description != null) ...[
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(product.description!),
                  ],
                  if (product.specifications != null) ...[
                    const SizedBox(height: 16),
                    const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    ...product.specifications!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 120, child: Text('${e.key}:', style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text(e.value.toString())),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer<CartProvider>(
            builder: (context, cart, _) {
              final inCart = cart.isInCart(product.id);
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: inCart ? null : () => cart.addToCart(product),
                      icon: Icon(inCart ? Icons.check : Icons.add_shopping_cart),
                      label: Text(inCart ? 'Added to Cart' : 'Add to Cart'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}