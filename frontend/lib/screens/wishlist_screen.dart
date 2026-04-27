import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import '../utils/currency_helper.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(title: Text(t('Wishlist', 'المفضلة')), backgroundColor: OmniTheme.surfaceColor, elevation: 0),
      body: wishlist.items.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.favorite_border, size: 64, color: OmniTheme.textMuted),
              const SizedBox(height: 16),
              Text(t('No favorites yet', 'لا توجد مفضلات'), style: TextStyle(color: OmniTheme.textSecondary)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              itemCount: wishlist.items.length,
              itemBuilder: (context, index) {
                final product = wishlist.items[index];
                return Dismissible(
                  key: Key('wish_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: OmniTheme.errorColor, borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => wishlist.removeFromWishlist(product.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: OmniTheme.backgroundColor, borderRadius: BorderRadius.circular(10)),
                        child: Image.network(product.mainImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, color: OmniTheme.textMuted)),
                      ),
                      title: Text(product.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}  ·  ${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp(product.price))} ₤', style: TextStyle(color: OmniTheme.textMuted, fontSize: 12)),
                      trailing: IconButton(icon: Icon(Icons.shopping_cart_outlined, color: OmniTheme.primaryColor), onPressed: () => cart.addToCart(product)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                    ),
                  ),
                );
              },
            ),
    );
  }
}