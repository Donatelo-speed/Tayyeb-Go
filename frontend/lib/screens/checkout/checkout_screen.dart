import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/tayyebgo_theme.dart';
import '../../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _noteController = TextEditingController();
  final _couponController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isPlacing = false;
  bool _isApplyingCoupon = false;
  String? _couponError;

  @override
  void dispose() {
    _noteController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    if (cart.isEmpty) return;

    setState(() => _isPlacing = true);

    try {
      final orderItems = cart.lines.map((l) => OrderItem(
        productId: l.product.id.toString(),
        name: l.product.displayName,
        basePrice: l.product.price,
        quantity: l.quantity,
        customerNote: l.customerNote,
      )).toList();

      final order = OrderModel(
        id: '',
        customerId: auth.user?.id ?? 'anonymous',
        customerName: auth.user?.displayName ?? 'Guest',
        vendorId: 'vendor-1',
        vendorName: 'Restaurant',
        status: OrderStatus.pending,
        paymentMethod: _paymentMethod == 'cash'
            ? OrderPaymentMethod.cash
            : OrderPaymentMethod.card,
        items: orderItems,
        deliveryAddress: const DeliveryAddress(
          street: '123 Main St',
          city: 'Riyadh',
        ),
        subtotal: cart.subtotal,
        deliveryFee: cart.deliveryFee,
        taxAmount: cart.tax,
        totalAmount: cart.grandTotal,
        discount: cart.promoDiscount,
        customerNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('orders').add(order.toFirestore());

      await cart.clearCart();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _OrderSuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $e'), backgroundColor: TayyebGoTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: TayyebGoTheme.surfaceColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Address',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: TayyebGoTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('123 Main Street, Riyadh\n+966 50 123 4567'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Method',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    value: 'cash',
                    title: 'Cash on Delivery',
                    icon: Icons.money,
                    selected: _paymentMethod,
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                  ),
                  _PaymentOption(
                    value: 'card',
                    title: 'Credit/Debit Card',
                    icon: Icons.credit_card,
                    selected: _paymentMethod,
                    onTap: () => setState(() => _paymentMethod = 'card'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coupon Code',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (cart.appliedCoupon != null)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: TayyebGoTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(cart.appliedCoupon!,
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            cart.removeCoupon();
                            _couponController.clear();
                          },
                          child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: TayyebGoTheme.backgroundColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isApplyingCoupon
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : ElevatedButton(
                                onPressed: () async {
                                  setState(() => _isApplyingCoupon = true);
                                  _couponError = await cart.applyCoupon(_couponController.text);
                                  setState(() => _isApplyingCoupon = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TayyebGoTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Apply', style: TextStyle(color: Colors.white)),
                              ),
                      ],
                    ),
                  if (_couponError != null) ...[
                    const SizedBox(height: 4),
                    Text(_couponError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Special Instructions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any notes for the restaurant...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: TayyebGoTheme.backgroundColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: cart.subtotal),
                  _SummaryRow(label: 'Delivery Fee', value: cart.deliveryFee),
                  _SummaryRow(label: 'Tax', value: cart.tax),
                  if (cart.promoDiscount > 0)
                    _SummaryRow(label: 'Discount (${cart.appliedCoupon ?? ""})', value: -cart.promoDiscount, isNegative: true),
                  const Divider(),
                  _SummaryRow(label: 'Total', value: cart.grandTotal, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isPlacing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TayyebGoTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isPlacing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Place Order',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String title;
  final IconData icon;
  final String selected;
  final VoidCallback onTap;
  const _PaymentOption({
    required this.value,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ListTile(
      leading: Icon(icon, color: isSelected ? TayyebGoTheme.primaryColor : Colors.grey),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: TayyebGoTheme.primaryColor)
          : const Icon(Icons.radio_button_off, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool isNegative;
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    final displayValue = isNegative ? '- \$${value.abs().toStringAsFixed(2)}' : '\$${value.toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 16 : 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(displayValue,
              style: TextStyle(
                  fontSize: bold ? 18 : 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: isNegative ? Colors.green : (bold ? TayyebGoTheme.primaryColor : null))),
        ],
      ),
    );
  }
}

class _OrderSuccessScreen extends StatelessWidget {
  const _OrderSuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: TayyebGoTheme.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 80, color: TayyebGoTheme.successColor),
              ),
              const SizedBox(height: 24),
              const Text('Order Placed Successfully!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Your order has been sent to the restaurant.\nYou can track it in the Orders tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TayyebGoTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TayyebGoTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continue Shopping',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
