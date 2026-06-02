import 'package:flutter/material.dart';
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
      return const AppScaffold(title: 'Checkout', body: SizedBox.shrink());
    }

    return AppScaffold(
      title: 'Checkout',
      showCart: _step == _CheckoutStep.form,
      body: _buildBody(cart, auth),
    );
  }

  Widget _buildBody(CartProvider cart, AuthProvider auth) {
    switch (_step) {
      case _CheckoutStep.processing:
        return _ProcessingState();
      case _CheckoutStep.error:
        return _ErrorState(
          message: _errorMessage,
          onRetry: () {
            setState(() => _step = _CheckoutStep.form);
          },
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a delivery address')));
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => PaymentSelectionSheet(
          totalAmount: Money(totalInCents),
          deliveryFee: Money((cart.deliveryFee * 100).round()),
          onSelected: (_) {},
        ),
      );

      if (result == null || !context.mounted) {
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
        paymentMethodType: result.name,
        commissionPercent: cart.commissionPercent ?? 15.0,
        fulfillmentType: _fulfillment.name,
        deliveryAddress: {'fullAddress': _addressCtrl.text.trim()},
      );

      if (result == PaymentMethodType.shamCash) {
        final shamCash = ShamCashService();
        final intentResult = await shamCash.createPaymentIntent(PaymentIntentRequest(
          orderId: orderId,
          amount: Money(totalInCents),
          method: result,
          commissionPercent: cart.commissionPercent ?? 15.0,
        ));
        if (!intentResult.success) {
          throw Exception(intentResult.errorMessage ?? 'Sham Cash record failed');
        }
      } else if (result == PaymentMethodType.stripe) {
        final stripe = StripeCheckoutService();
        final intentResult = await stripe.createPaymentIntent(PaymentIntentRequest(
          orderId: orderId,
          amount: Money(totalInCents),
          method: result,
          commissionPercent: cart.commissionPercent ?? 15.0,
        ));
        if (!intentResult.success) {
          throw Exception(intentResult.errorMessage ?? 'Stripe payment failed');
        }
        if (intentResult.checkoutUrl != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Redirect to payment: ${intentResult.checkoutUrl}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'Open', onPressed: () {}),
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

// =============================================================================
// Checkout Form State
// =============================================================================

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
        Text('Delivery Details', style: TayyebGoTheme.heading3),
        const SizedBox(height: 12),
        TextField(
          controller: addressCtrl,
          decoration: const InputDecoration(labelText: 'Delivery Address', hintText: 'Street, building, apartment'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: instructionsCtrl,
          decoration: const InputDecoration(labelText: 'Special Instructions (optional)', hintText: 'Leave at door, ring bell, etc.'),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        Text('Fulfillment Type', style: TayyebGoTheme.heading3),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _fulfillmentTile(FulfillmentType.delivery, Icons.delivery_dining, 'Delivery', fulfillment == FulfillmentType.delivery, onFulfillmentChanged)),
            const SizedBox(width: 12),
            Expanded(child: _fulfillmentTile(FulfillmentType.pickup, Icons.store, 'Pickup', fulfillment == FulfillmentType.pickup, onFulfillmentChanged)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Order Summary', style: TayyebGoTheme.heading3),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: TayyebGoTheme.cardDecoration,
          child: Column(children: [
            _summaryRow('Items (${cart.totalQuantity})', '\$${cart.subtotal.toStringAsFixed(2)}'),
            _summaryRow('Delivery Fee', fulfillment == FulfillmentType.pickup ? 'Free' : '\$${cart.deliveryFee.toStringAsFixed(2)}'),
            _summaryRow('Tax', '\$${cart.tax.toStringAsFixed(2)}'),
            if (cart.promoDiscount > 0) _summaryRow('Discount', '-\$${cart.promoDiscount.toStringAsFixed(2)}'),
            const Divider(height: 20),
            _summaryRow('Total', '\$${cart.grandTotal.toStringAsFixed(2)}', bold: true),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPlaceOrder,
            child: Text('Place Order — \$${cart.grandTotal.toStringAsFixed(2)}'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _fulfillmentTile(FulfillmentType type, IconData icon, String label, bool selected, ValueChanged<FulfillmentType> onChanged) {
    return InkWell(
      onTap: () => onChanged(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? TayyebGoTheme.primaryColor : TayyebGoTheme.dividerColor, width: selected ? 2 : 1),
          color: selected ? TayyebGoTheme.primaryColor.withValues(alpha: 0.05) : TayyebGoTheme.surfaceColor,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? TayyebGoTheme.primaryColor : TayyebGoTheme.textMuted, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? TayyebGoTheme.primaryColor : TayyebGoTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: bold ? TayyebGoTheme.textPrimary : TayyebGoTheme.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ]),
    );
  }
}

// =============================================================================
// Processing State
// =============================================================================

class _ProcessingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: TayyebGoTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text('Processing your order', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Please wait while we confirm your order...',
              style: TextStyle(color: TayyebGoTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _PulseDots(),
          ],
        ),
      ),
    );
  }
}

class _PulseDots extends StatefulWidget {
  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final anim = TweenSequence([
              TweenSequenceItem(tween: ConstantTween<double>(0.3), weight: delay),
              TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 0.3),
              TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 0.2),
              TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 0.3),
              TweenSequenceItem(tween: ConstantTween<double>(0.3), weight: 1.0 - delay - 0.8),
            ]).evaluate(AlwaysStoppedAnimation(_controller.value));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: anim,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: TayyebGoTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// =============================================================================
// Error State
// =============================================================================

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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TayyebGoTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: TayyebGoTheme.errorColor),
            ),
            const SizedBox(height: 20),
            Text('Order Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TayyebGoTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => GoRouter.of(context).go('/cart'),
              child: const Text('Back to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
