import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'omni_catalog_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          const LegacyCatalogWidget(),
          const OmniCatalogScreen(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
          Tab(icon: Icon(Icons.explore), text: 'Explore'),
        ],
      ),
    );
  }
}

class LegacyCatalogWidget extends StatefulWidget {
  const LegacyCatalogWidget({super.key});

  @override
  State<LegacyCatalogWidget> createState() => _LegacyCatalogState();
}

class _LegacyCatalogState extends State<LegacyCatalogWidget> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String _sortBy = 'name';
  bool _sortAsc = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    Provider.of<ProductProvider>(context, listen: false).searchProducts(query);
  }

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    Provider.of<ProductProvider>(context, listen: false).filterByCategory(category);
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAsc = !_sortAsc;
      } else {
        _sortBy = sortBy;
        _sortAsc = true;
      }
    });
    Provider.of<ProductProvider>(context, listen: false).sortProducts(sortBy, _sortAsc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniMarket'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: _onSearch,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text('Name ${_sortBy == 'name' ? (_sortAsc ? '↑' : '↓') : ''}')),
              PopupMenuItem(value: 'price', child: Text('Price ${_sortBy == 'price' ? (_sortAsc ? '↑' : '↓') : ''}')),
              PopupMenuItem(value: 'created_at', child: Text('Newest ${_sortBy == 'created_at' ? (_sortAsc ? '↑' : '↓') : ''}')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final categoryNames = provider.uniqueCategories;
                final categories = ['All', ...categoryNames];
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == 'All' ? _selectedCategory == null : _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _onCategoryChanged(category == 'All' ? null : category),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No products found', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => provider.loadProducts(refresh: true),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    return _ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: product.imageUrls?.isNotEmpty == true
                    ? CachedNetworkImage(imageUrl: product.mainImageUrl, fit: BoxFit.cover, placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (_, __, ___) => const Icon(Icons.image, size: 48))
                    : const Icon(Icons.image, size: 48),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            final inCart = cart.isInCart(product.id);
                            return IconButton(
                              icon: Icon(inCart ? Icons.check_circle : Icons.add_shopping_cart, color: inCart ? Colors.green : null),
                              onPressed: inCart ? null : () => cart.addToCart(product),
                              visualDensity: VisualDensity.compact,
                            );
                          },
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