import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import '../utils/currency_helper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0;
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final cart = context.watch<CartProvider>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(title: Text(t('Checkout', 'إتمام الطلب')), backgroundColor: OmniTheme.surfaceColor, elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('Delivery Address', 'عنوان التوصيل'), style: TextStyle(fontWeight: FontWeight.bold, color: OmniTheme.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.location_on, color: OmniTheme.primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t('Home Address', 'عنوان المنزل'), style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(t(' Damascus, Syria', ' دمشق، سوريا'), style: TextStyle(fontSize: 12, color: OmniTheme.textMuted)),
                    ])),
                    TextButton(onPressed: () {}, child: Text(t('Change', 'تغيير'))),
                  ]),
                ),
                const SizedBox(height: 20),
                Text(t('Payment Method', 'طريقة الدفع'), style: TextStyle(fontWeight: FontWeight.bold, color: OmniTheme.textPrimary)),
                const SizedBox(height: 8),
                _PaymentOption(icon: Icons.money, label: t('Cash on Delivery', 'الدفع عند الاستلام'), selected: _selectedPayment == 0, onTap: () => setState(() => _selectedPayment = 0)),
                _PaymentOption(icon: Icons.credit_card, label: t('Credit Card', 'بطاقة ائتمان'), selected: _selectedPayment == 1, onTap: () => setState(() => _selectedPayment = 1)),
                _PaymentOption(icon: Icons.account_balance_wallet, label: t('Wallet', 'المحفظة'), selected: _selectedPayment == 2, onTap: () => setState(() => _selectedPayment = 2)),
                const SizedBox(height: 20),
                Text(t('Order Summary', 'ملخص الطلب'), style: TextStyle(fontWeight: FontWeight.bold, color: OmniTheme.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                  child: Column(children: [
                    _SummaryRow(label: t('Subtotal', 'المجموع'), value: '\$${cart.subtotal.toStringAsFixed(2)}'),
                    _SummaryRow(label: t('Delivery', 'التوصيل'), value: cart.deliveryFee > 0 ? '\$${cart.deliveryFee.toStringAsFixed(2)}' : t('Free', 'مجاني')),
                    Divider(height: 20),
                    _SummaryRow(label: t('Total', 'الإجمالي'), value: '\$${cart.total.toStringAsFixed(2)}', isBold: true),
                    const SizedBox(height: 4),
                    Text('${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp(cart.total))} ₤', style: TextStyle(fontSize: 12, color: OmniTheme.textMuted)),
                  ]),
                ),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))]),
            child: SafeArea(child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(t('Total', 'الإجمالي'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('\$${cart.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: OmniTheme.primaryColor)),
              ]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 52, child: FilledButton(
                onPressed: _isPlacing ? null : () async {
                  setState(() => _isPlacing = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) {
                    cart.clearCart();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Text(t('Order placed!', 'تم الطلب!'))]),
                      backgroundColor: OmniTheme.successColor,
                    ));
                  }
                },
                child: _isPlacing ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(t('Place Order', 'تأكيد الطلب'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )),
            ])),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? OmniTheme.primaryColor : OmniTheme.borderColor, width: selected ? 2 : 1)),
        child: Row(children: [
          Icon(icon, color: selected ? OmniTheme.primaryColor : OmniTheme.textMuted),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          const Spacer(),
          if (selected) Icon(Icons.check_circle, color: OmniTheme.primaryColor),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: OmniTheme.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isBold ? OmniTheme.primaryColor : null)),
    ]));
  }
}