import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import '../utils/currency_helper.dart';

class ProductDetailScreen extends StatelessWidget {
  final dynamic product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;
    final isInCart = cart.isInCart(product.id);
    final isWishlisted = wishlist.isInWishlist(product.id);

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: OmniTheme.surfaceColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: OmniTheme.surfaceColor, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: OmniTheme.surfaceColor, shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: isWishlisted ? Colors.red : OmniTheme.textPrimary),
                  onPressed: () => wishlist.toggleWishlist(product),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [
              Container(color: OmniTheme.backgroundColor, child: Image.network(product.mainImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, size: 80, color: OmniTheme.textMuted))),
              if (product.safeDiscount > 0) Positioned(top: 60, left: 16, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: OmniTheme.errorColor, borderRadius: BorderRadius.circular(20)),
                child: Text('-${(product.safeDiscount * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
            ])),
          ),
          SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (product.category != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(product.category, style: TextStyle(color: OmniTheme.primaryColor, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              Text(product.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: OmniTheme.primaryColor)),
                const SizedBox(width: 8),
                Text('${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp(product.price))} ₤', style: TextStyle(fontSize: 14, color: OmniTheme.textMuted)),
              ]),
              const SizedBox(height: 16),
              Text(product.description ?? '', style: TextStyle(color: OmniTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: OmniTheme.backgroundColor, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.inventory_2, size: 20, color: OmniTheme.textMuted),
                    const SizedBox(width: 8),
                    Text('${product.stockQuantity ?? 0} ${t('in stock', 'متوفر')}', style: TextStyle(color: OmniTheme.textSecondary)),
                  ]),
                )),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => isInCart ? cart.removeFromCart(product.id) : cart.addToCart(product),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(isInCart ? Icons.check : Icons.shopping_cart, size: 22),
                    const SizedBox(width: 10),
                    Text(isInCart ? t('Remove from Cart', 'إزالة من السلة') : t('Add to Cart', 'إضافة للسلة'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          )),
        ],
      ),
    );
  }
}