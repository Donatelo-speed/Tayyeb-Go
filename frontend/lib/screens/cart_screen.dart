import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import '../utils/currency_helper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('Shopping Cart', 'السلة')),
        backgroundColor: OmniTheme.surfaceColor,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.items.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showClearDialog(context, locale),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.08), shape: BoxShape.circle),
                    child: Icon(Icons.shopping_cart_outlined, size: 60, color: OmniTheme.primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(t('Your cart is empty', 'سلة التسوق فارغة'), style: TextStyle(fontSize: 18, color: OmniTheme.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(t('Add products to get started', 'أضف منتجات للبدء'), style: TextStyle(color: OmniTheme.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cart.itemList.length,
                  itemBuilder: (context, index) {
                    final item = cart.itemList[index];
                    return Dismissible(
                      key: Key('cart_${item.productId}'),
                      direction: isArabic ? DismissDirection.startToEnd : DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: OmniTheme.errorColor, borderRadius: BorderRadius.circular(16)),
                        alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => cart.removeFromCart(item.productId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: OmniTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(color: OmniTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.product != null
                                      ? CachedNetworkImage(imageUrl: item.product!.mainImageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Icon(Icons.shopping_bag, color: OmniTheme.textMuted))
                                      : Icon(Icons.shopping_bag, color: OmniTheme.textMuted),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Text('\$${item.price.toStringAsFixed(2)}', style: TextStyle(color: OmniTheme.textSecondary, fontSize: 13)),
                                      const SizedBox(width: 6),
                                      Text('${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp(item.price))} ₤', style: TextStyle(fontSize: 11, color: OmniTheme.textMuted)),
                                    ]),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      _QtyBtn(icon: Icons.remove, onPressed: () => cart.decrement(item.productId)),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                      _QtyBtn(icon: Icons.add, onPressed: () => cart.increment(item.productId)),
                                    ]),
                                  ],
                                ),
                              ),
                              Column(children: [
                                Text('\$${item.total.toStringAsFixed(2)}', style: TextStyle(color: OmniTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp(item.total))} ₤', style: TextStyle(fontSize: 10, color: OmniTheme.textMuted)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: OmniTheme.surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
                ),
                child: SafeArea(child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t('Subtotal', 'المجموع'), style: TextStyle(color: OmniTheme.textSecondary, fontSize: 14)),
                    Text('\$${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t('Delivery', 'التوصيل'), style: TextStyle(color: OmniTheme.textSecondary, fontSize: 14)),
                    Text(cart.deliveryFee > 0 ? '\$${cart.deliveryFee.toStringAsFixed(2)}' : t('Free', 'مجاني'), style: TextStyle(color: cart.deliveryFee == 0 ? OmniTheme.successColor : null, fontSize: 14)),
                  ]),
                  if (cart.deliveryFee > 0) ...[
                    const SizedBox(height: 4),
                    Text(t('Free delivery on orders over \$50', 'توصيل مجاني للطلبات فوق 50 دولار'), style: TextStyle(color: OmniTheme.textMuted, fontSize: 11)),
                  ],
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t('Total', 'الإجمالي'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('\$${cart.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: OmniTheme.primaryColor)),
                      Text('${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp(cart.total))} ₤', style: TextStyle(fontSize: 11, color: OmniTheme.textMuted)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text(t('Proceed to Checkout', 'إتمام الشراء'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ])),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, LocaleBox locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('Clear Cart', 'مسح السلة')),
        content: Text(locale.t('Remove all items?', 'إزالة كل العناصر؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.t('Cancel', 'إلغاء'))),
          FilledButton(
            onPressed: () { context.read<CartProvider>().clearCart(); Navigator.pop(context); },
            style: FilledButton.styleFrom(backgroundColor: OmniTheme.errorColor),
            child: Text(locale.t('Clear', 'مسح')),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _QtyBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: OmniTheme.backgroundColor, borderRadius: BorderRadius.circular(8)),
      child: IconButton(icon: Icon(icon, size: 18), onPressed: onPressed, padding: const EdgeInsets.all(8), constraints: const BoxConstraints()),
    );
  }
}