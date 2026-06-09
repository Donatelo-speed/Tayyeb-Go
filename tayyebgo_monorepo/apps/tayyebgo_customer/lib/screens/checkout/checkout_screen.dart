import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

enum _CheckoutStep { form, processing, error, done }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  FulfillmentType _fulfillment = FulfillmentType.delivery;
  _CheckoutStep _step = _CheckoutStep.form;
  String _errorMessage = '';
  PaymentMethodType? _selectedPaymentMethod;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    if (cart.isEmpty && _step != _CheckoutStep.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/cart');
      });
      return Scaffold(backgroundColor: context.backgroundColor, body: const SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(context, cart, auth),
    );
  }

  Widget _buildBody(BuildContext context, CartProvider cart, AuthProvider auth) {
    switch (_step) {
      case _CheckoutStep.processing:
        return const _ProcessingState();
      case _CheckoutStep.error:
        return _ErrorState(
          message: _errorMessage,
          onRetry: () => setState(() => _step = _CheckoutStep.form),
        );
      case _CheckoutStep.done:
        return const SizedBox.shrink();
      case _CheckoutStep.form:
        return _CheckoutForm(
          addressCtrl: _addressCtrl,
          instructionsCtrl: _instructionsCtrl,
          fulfillment: _fulfillment,
          cart: cart,
          onFulfillmentChanged: (v) => setState(() => _fulfillment = v),
          onPlaceOrder: () => _placeOrder(context, cart, auth),
        );
    }
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart, AuthProvider auth) async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a delivery address', style: GoogleFonts.inter()),
          backgroundColor: context.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _step = _CheckoutStep.processing;
      _errorMessage = '';
    });

    try {
      final totalInCents = (cart.grandTotal * 100).round();
      final result = await showModalBottomSheet<PaymentMethodType>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentSelectionSheet(
          totalAmount: Money(totalInCents),
          deliveryFee: Money((cart.deliveryFee * 100).round()),
          onSelected: (method) => setState(() => _selectedPaymentMethod = method),
        ),
      );
      _selectedPaymentMethod = result;

      if (_selectedPaymentMethod == null || !context.mounted) {
        setState(() => _step = _CheckoutStep.form);
        return;
      }

      setState(() => _step = _CheckoutStep.processing);

      final orderService = OrderPlacementService();
      final orderId = await orderService.placeOrder(
        customerId: auth.user?.id ?? '',
        restaurantId: cart.restaurantId ?? '',
        restaurantName: cart.restaurantName ?? '',
        items: cart.lines.map((l) => l.toJson()).toList(),
        totalAmountInCents: totalInCents,
        paymentMethodType: _selectedPaymentMethod!.name,
        commissionPercent: cart.commissionPercent ?? 15.0,
        fulfillmentType: _fulfillment.name,
        deliveryAddress: {'fullAddress': _addressCtrl.text.trim()},
      );

      if (_selectedPaymentMethod == PaymentMethodType.shamCash) {
        final shamCash = ShamCashService();
        final intentResult = await shamCash.createPaymentIntent(PaymentIntentRequest(
          orderId: orderId,
          amount: Money(totalInCents),
          method: _selectedPaymentMethod!,
          commissionPercent: cart.commissionPercent ?? 15.0,
        ));
        if (!intentResult.success) throw Exception(intentResult.errorMessage ?? 'Sham Cash record failed');
      } else if (_selectedPaymentMethod == PaymentMethodType.stripe) {
        final stripe = StripeCheckoutService();
        final intentResult = await stripe.createPaymentIntent(PaymentIntentRequest(
          orderId: orderId,
          amount: Money(totalInCents),
          method: _selectedPaymentMethod!,
          commissionPercent: cart.commissionPercent ?? 15.0,
        ));
        if (!intentResult.success) throw Exception(intentResult.errorMessage ?? 'Stripe payment failed');
        if (intentResult.checkoutUrl != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Redirect to payment: ${intentResult.checkoutUrl}', style: GoogleFonts.inter()),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }

      if (context.mounted) {
        await cart.clearCart();
        setState(() => _step = _CheckoutStep.done);
        if (context.mounted) context.go('/tracking/$orderId');
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _step = _CheckoutStep.error;
          _errorMessage = e.toString();
        });
      }
    }
  }
}

class _CheckoutForm extends StatelessWidget {
  final TextEditingController addressCtrl;
  final TextEditingController instructionsCtrl;
  final FulfillmentType fulfillment;
  final CartProvider cart;
  final ValueChanged<FulfillmentType> onFulfillmentChanged;
  final VoidCallback onPlaceOrder;

  const _CheckoutForm({
    required this.addressCtrl,
    required this.instructionsCtrl,
    required this.fulfillment,
    required this.cart,
    required this.onFulfillmentChanged,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(context, 'Delivery Details'),
        const SizedBox(height: 12),
        _buildField(context, 'Delivery Address', Icons.location_on_outlined, addressCtrl, maxLines: 2, hint: 'Street, building, apartment'),
        const SizedBox(height: 12),
        _buildField(context, 'Special Instructions', Icons.edit_note_rounded, instructionsCtrl, maxLines: 2, hint: 'Leave at door, ring bell, etc.'),
        const SizedBox(height: 24),
        _buildSection(context, 'Fulfillment'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _fulfillmentTile(context, FulfillmentType.delivery, Icons.delivery_dining_rounded, 'Delivery')),
            const SizedBox(width: 12),
            Expanded(child: _fulfillmentTile(context, FulfillmentType.pickup, Icons.store_rounded, 'Pickup')),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(context, 'Order Summary'),
        const SizedBox(height: 12),
        _buildSummaryCard(context, cart),
        const SizedBox(height: 16),
        _buildTipSection(context),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onPlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Place Order — \$${cart.grandTotal.toStringAsFixed(2)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMutedColor, letterSpacing: 0.3));
  }

  Widget _buildField(BuildContext context, String label, IconData icon, TextEditingController ctrl, {int maxLines = 1, String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: context.textMutedColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _fulfillmentTile(BuildContext context, FulfillmentType type, IconData icon, String label) {
    final selected = fulfillment == type;
    return GestureDetector(
      onTap: () => onFulfillmentChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor.withValues(alpha: 0.1) : context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.primaryColor : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? context.primaryColor : context.textMutedColor, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: selected ? context.primaryColor : context.textMutedColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          _summaryRow(context, 'Items (${cart.totalQuantity})', '\$${cart.subtotal.toStringAsFixed(2)}'),
          _summaryRow(context, 'Delivery Fee', fulfillment == FulfillmentType.pickup ? 'Free' : '\$${cart.deliveryFee.toStringAsFixed(2)}'),
          _summaryRow(context, 'Tax', '\$${cart.tax.toStringAsFixed(2)}'),
          if (cart.promoDiscount > 0)
            _summaryRow(context, 'Discount', '-\$${cart.promoDiscount.toStringAsFixed(2)}', valueColor: context.successColor),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.borderColor),
          ),
          _summaryRow(context, 'Total', '\$${cart.grandTotal.toStringAsFixed(2)}', bold: true),
        ],
      ),
    );
  }

  Widget _buildTipSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tip for driver', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              _tipButton(context, 'No Tip'),
              const SizedBox(width: 8),
              _tipButton(context, '5%'),
              const SizedBox(width: 8),
              _tipButton(context, '10%'),
              const SizedBox(width: 8),
              _tipButton(context, '15%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipButton(BuildContext context, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textMutedColor)),
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: bold ? context.textPrimaryColor : context.textMutedColor, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: valueColor ?? context.textPrimaryColor)),
        ],
      ),
    );
  }
}

class _ProcessingState extends StatelessWidget {
  const _ProcessingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 40, color: context.primaryColor),
            ),
            const SizedBox(height: 28),
            Text('Processing your order', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
            const SizedBox(height: 8),
            Text('Please wait while we confirm your order...', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: context.primaryColor)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 40, color: context.errorColor),
            ),
            const SizedBox(height: 24),
            Text('Order Failed', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
            const SizedBox(height: 8),
            Text(message, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Try Again', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.go('/cart'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textMutedColor,
                  side: BorderSide(color: context.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back to Cart', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
