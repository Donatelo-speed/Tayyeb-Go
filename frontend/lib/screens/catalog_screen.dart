import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import '../utils/currency_helper.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _sortBy = 'newest';
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final products = context.watch<ProductProvider>();
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;

    var sorted = List<Product>.from(products.products);
    switch (_sortBy) {
      case 'price_low': sorted.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'price_high': sorted.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'name': sorted.sort((a, b) => a.displayName.compareTo(b.displayName)); break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('OmniMarket', 'أومني')),
        actions: [
          IconButton(icon: Icon(_gridView ? Icons.view_list : Icons.grid_view, size: 22), onPressed: () => setState(() => _gridView = !_gridView), tooltip: t('Toggle', 'تبديل')),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, size: 22),
            tooltip: t('Sort', 'ترتيب'),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'newest', child: Text(t('Newest', 'الأحدث'))),
              PopupMenuItem(value: 'price_low', child: Text(t('Price: Low to High', 'ال��عر: من الأقل'))),
              PopupMenuItem(value: 'price_high', child: Text(t('Price: High to Low', 'السعر: من الأعلى'))),
              PopupMenuItem(value: 'name', child: Text(t('Name A-Z', 'اسم'))),
            ],
          ),
        ],
      ),
      body: products.isLoading
          ? const LoadingWidget()
          : sorted.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: OmniTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(t('No products found', 'لا توجد منتجات'), style: TextStyle(color: OmniTheme.textSecondary)),
                ]))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                    final isSmall = constraints.maxWidth < 400;
                    return GridView.builder(
                      padding: EdgeInsets.all(isSmall ? 8 : 12),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridView ? crossCount : 1,
                        childAspectRatio: _gridView ? (isSmall ? 0.65 : 0.72) : 3.0,
                        crossAxisSpacing: isSmall ? 8 : 12,
                        mainAxisSpacing: isSmall ? 8 : 12,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final product = sorted[index];
                        return _ProductCard(product: product, isSmall: isSmall, gridView: _gridView, isWishlisted: wishlist.isInWishlist(product.id), isInCart: cart.isInCart(product.id));
                      },
                    );
                  },
                ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isSmall;
  final bool gridView;
  final bool isWishlisted;
  final bool isInCart;

  const _ProductCard({required this.product, required this.isSmall, required this.gridView, required this.isWishlisted, required this.isInCart});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (product.id.hashCode % 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: OmniTheme.backgroundColor, child: Image.network(product.mainImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, size: 40, color: OmniTheme.textMuted))),
                    Positioned(top: 8, right: 8, child: GestureDetector(
                      onTap: () => wishlist.toggleWishlist(product),
                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: OmniTheme.surfaceColor, shape: BoxShape.circle), child: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: isWishlisted ? Colors.red : OmniTheme.textMuted, size: 18)),
                    )),
                    if (product.safeDiscount > 0) Positioned(top: 8, left: 8, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: OmniTheme.errorColor, borderRadius: BorderRadius.circular(20)),
                      child: Text('-${(product.safeDiscount * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(10), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 11 : 13)),
                  const Spacer(),
                  Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(color: OmniTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: isSmall ? 13 : 15)),
                  Text('${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp(product.price))} ₤', style: TextStyle(fontSize: 10, color: OmniTheme.textMuted)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => isInCart ? cart.removeFromCart(product.id) : cart.addToCart(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInCart ? OmniTheme.backgroundColor : OmniTheme.primaryColor,
                        foregroundColor: isInCart ? OmniTheme.textSecondary : Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(isInCart ? Icons.check : Icons.add, size: 14),
                        const SizedBox(width: 4),
                        Text(isInCart ? t('Added', 'مضاف') : t('Add', 'إضافة'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ))),
            ],
          ),
        ),
      ),
    );
  }
}