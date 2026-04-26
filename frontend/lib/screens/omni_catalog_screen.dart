import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../widgets/live_widgets.dart';
import '../widgets/alive_widgets.dart';
import 'product_detail_screen.dart';

class OmniCatalogScreen extends StatefulWidget {
  const OmniCatalogScreen({super.key});

  @override
  State<OmniCatalogScreen> createState() => _OmniCatalogScreenState();
}

class _OmniCatalogScreenState extends State<OmniCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  final PageController _bannerController = PageController();
  int _currentBanner = 0;

  final List<Map<String, dynamic>> _categoryIcons = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Electronics', 'icon': Icons.devices},
    {'name': 'Audio', 'icon': Icons.headphones},
    {'name': 'Accessories', 'icon': Icons.watch},
    {'name': 'Storage', 'icon': Icons.sd_card},
    {'name': 'Office', 'icon': Icons.work},
    {'name': 'Gaming', 'icon': Icons.sports_esports},
    {'name': 'Mobile', 'icon': Icons.smartphone},
    {'name': 'Computing', 'icon': Icons.computer},
    {'name': 'Smart Home', 'icon': Icons.home_max},
  ];

  final List<String> _banners = [
    'https://images.unsplash.com/photo-1607082349566-187342705e0f?w=800',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
    'https://images.unsplash.com/photo-1472851294608-062f824d4a55?w=800',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    Provider.of<ProductProvider>(context, listen: false).filterByCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 120,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [Colors.white, const Color(0xFFF5F5F5)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search products...',
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onChanged: (v) => Provider.of<ProductProvider>(context, listen: false).searchProducts(v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey[100],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.tune, color: isDark ? Colors.white : Colors.black87),
                                onPressed: () => _showFilterSheet(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Banner Carousel
          SliverToBoxAdapter(
            child: Container(
              height: 180,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (i) => setState(() => _currentBanner = i),
                  itemCount: _banners.length,
                  itemBuilder: (ctx, i) => Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: _banners[i],
                        fit: BoxFit.cover,
                        color: Colors.grey[300],
                        colorBlendMode: BlendMode.saturation,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i == 0 ? 'Summer Sale - 50% Off' : i == 1 ? 'New Arrivals' : 'Free Delivery',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              i == 0 ? 'Limited time offer' : i == 1 ? 'Check latest products' : 'On orders over \$50',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Banner Dots
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentBanner == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentBanner == i ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
          ),

          // Live Customer Indicator
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LiveCustomerIndicator(
                count: 127,
                label: 'shopping now',
              ),
            ),
          ),

          // Flash Sale Banner
          SliverToBoxAdapter(
            child: FlashSaleBanner(
              title: 'FLASH SALE',
              endTime: DateTime.now().add(const Duration(hours: 4, minutes: 32)),
              color: Colors.red,
            ),
          ),

          // Categories Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // Categories Horizontal List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categoryIcons.length,
                itemBuilder: (ctx, i) {
                  final cat = _categoryIcons[i];
                  final isSelected = cat['name'] == 'All' 
                      ? _selectedCategory == null 
                      : _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => _onCategoryChanged(cat['name'] == 'All' ? null : cat['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 80,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : (isDark ? Colors.white10 : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.2) 
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'],
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Featured Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Featured Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ),

          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ShimmerCard(),
                      childCount: 6,
                    ),
                  );
                }

                if (provider.products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No products found'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => provider.loadProducts(refresh: true),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ProductCardNew(product: provider.products[i]),
                    childCount: provider.products.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Price Range'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Min'), keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Max'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Sort By'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('Price: Low to High'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('Price: High to Low'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('Newest'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('Popular'), selected: false, onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCardNew extends StatelessWidget {
  final Product product;

  const _ProductCardNew({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252542) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: product.imageUrls?.isNotEmpty == true
                          ? CachedNetworkImage(
                              imageUrl: product.mainImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.grey[300]),
                              ),
                            )
                          : const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
                  // Wishlist Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black54 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.favorite_border, size: 20, color: Colors.red[400]),
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, size: 16, color: Colors.white),
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

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}