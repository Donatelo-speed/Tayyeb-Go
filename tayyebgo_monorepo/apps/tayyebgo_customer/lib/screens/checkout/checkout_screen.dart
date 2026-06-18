import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'stripe_stub.dart' if (dart.library.io) 'stripe_stub_native.dart';

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
  bool _isExpress = false;
  DateTime? _scheduledTime;
  CustomerSubscription? _activeSubscription;
  double _subscriptionDiscount = 0;
  bool _subscriptionFreeDelivery = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSubscription());
  }

  Future<void> _checkSubscription() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    try {
      final sub = await SubscriptionService.instance.getActiveSubscription(userId);
      if (sub != null && mounted) {
        final cart = context.read<CartProvider>();
        final subtotalCents = (cart.subtotal * 100).round();
        final benefits = SubscriptionService.instance.applyBenefits(
          subscription: sub,
          orderSubtotal: Money(subtotalCents),
          isDelivery: _fulfillment == FulfillmentType.delivery,
        );
        setState(() {
          _activeSubscription = sub;
          _subscriptionDiscount = benefits.discount.inDollars;
          _subscriptionFreeDelivery = benefits.freeDelivery;
        });
      }
    } catch (_) {}
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    AnimatedPressScale(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(
                            color: context.borderColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: context.textPrimaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Checkout',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: context.textPrimaryColor,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildBody(context, cart, auth),
            ),
          ],
        ),
      ),
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
          onFulfillmentChanged: (v) {
            setState(() => _fulfillment = v);
            _checkSubscription();
          },
          onPlaceOrder: () => _placeOrder(context, cart, auth),
          isExpress: _isExpress,
          onExpressChanged: (v) => setState(() => _isExpress = v),
          scheduledTime: _scheduledTime,
          onScheduledTimeChanged: (v) => setState(() => _scheduledTime = v),
          activeSubscription: _activeSubscription,
          subscriptionDiscount: _subscriptionDiscount,
          subscriptionFreeDelivery: _subscriptionFreeDelivery,
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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      );
      return;
    }

    setState(() {
      _step = _CheckoutStep.processing;
      _errorMessage = '';
    });

    try {
      final effectiveDeliveryFee = _subscriptionFreeDelivery && _fulfillment == FulfillmentType.delivery
          ? 0.0
          : cart.deliveryFee;
      final totalBeforeDiscount = cart.subtotal + effectiveDeliveryFee + cart.tax;
      final totalInCents = ((totalBeforeDiscount - cart.promoDiscount - _subscriptionDiscount).clamp(0.0, double.infinity) * 100).round();
      final result = await showModalBottomSheet<PaymentMethodType>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentSelectionSheet(
          totalAmount: Money(totalInCents),
          deliveryFee: Money((effectiveDeliveryFee * 100).round()),
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
        promoCode: cart.appliedCoupon,
        promoDiscount: cart.promoDiscount > 0 ? cart.promoDiscount : null,
        subtotalCents: (cart.subtotal * 100).round(),
        deliveryFeeCents: (effectiveDeliveryFee * 100).round(),
        taxCents: (cart.tax * 100).round(),
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

        if (intentResult.clientSecret != null && context.mounted) {
          final stripeSuccess = await _processStripePayment(context, intentResult.clientSecret!);
          if (!stripeSuccess) throw Exception('Card payment was declined');
        }
      }

      if (context.mounted) {
        if (cart.appliedCoupon != null) {
          try {
            await PromoAbuseService.instance.recordPromoUsage(
              promoCode: cart.appliedCoupon!,
              customerId: auth.user?.id ?? '',
              phone: auth.user?.phone,
            );
            final promoSnap = await FirebaseFirestore.instance
                .collection('promos')
                .where('code', isEqualTo: cart.appliedCoupon!)
                .get();
            for (final doc in promoSnap.docs) {
              await doc.reference.update({
                'usageCount': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (_) {}
        }
        await cart.clearCart();
        setState(() => _step = _CheckoutStep.done);

        // Show success animation overlay, then navigate
        if (context.mounted) {
          late OverlayEntry entry;
          entry = OverlayEntry(
            builder: (_) => OrderSuccessAnimation(
              orderId: orderId,
              onDismiss: () {
                entry.remove();
                if (context.mounted) context.push('/tracking/$orderId');
              },
            ),
          );
          Overlay.of(context).insert(entry);
        }
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

  Future<bool> _processStripePayment(BuildContext context, String clientSecret) async {
    try {
      final stripe = createStripeWrapper();
      await stripe.initPaymentSheet(
        clientSecret: clientSecret,
        merchantDisplayName: 'TayyebGo',
      );
      await stripe.presentPaymentSheet();
      return true;
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().contains('cancelled') ? 'Payment was cancelled' : 'Payment failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.inter()),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
        );
      }
      return false;
    }
  }
}

class _CheckoutForm extends StatefulWidget {
  final TextEditingController addressCtrl;
  final TextEditingController instructionsCtrl;
  final FulfillmentType fulfillment;
  final CartProvider cart;
  final ValueChanged<FulfillmentType> onFulfillmentChanged;
  final VoidCallback onPlaceOrder;
  final bool isExpress;
  final ValueChanged<bool> onExpressChanged;
  final DateTime? scheduledTime;
  final ValueChanged<DateTime?> onScheduledTimeChanged;
  final CustomerSubscription? activeSubscription;
  final double subscriptionDiscount;
  final bool subscriptionFreeDelivery;

  const _CheckoutForm({
    required this.addressCtrl,
    required this.instructionsCtrl,
    required this.fulfillment,
    required this.cart,
    required this.onFulfillmentChanged,
    required this.onPlaceOrder,
    this.isExpress = false,
    required this.onExpressChanged,
    this.scheduledTime,
    required this.onScheduledTimeChanged,
    this.activeSubscription,
    this.subscriptionDiscount = 0,
    this.subscriptionFreeDelivery = false,
  });

  @override
  State<_CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<_CheckoutForm> {
  String? _selectedTip;

  double _effectiveTotal() {
    final deliveryFee = widget.subscriptionFreeDelivery && widget.fulfillment == FulfillmentType.delivery
        ? 0.0
        : widget.cart.deliveryFee;
    final total = widget.cart.subtotal + deliveryFee + widget.cart.tax - widget.cart.promoDiscount - widget.subscriptionDiscount;
    return total.clamp(0.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        AnimatedFadeSlide(
          delay: 100,
          duration: const Duration(milliseconds: 500),
          child: _buildSection(context, 'Delivery Details'),
        ),
        const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: 150,
          duration: const Duration(milliseconds: 500),
          child: _buildField(context, 'Delivery Address', Icons.location_on_outlined, widget.addressCtrl, maxLines: 2, hint: 'Street, building, apartment'),
        ),
        const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: 200,
          duration: const Duration(milliseconds: 500),
          child: _buildField(context, 'Special Instructions', Icons.edit_note_rounded, widget.instructionsCtrl, maxLines: 2, hint: 'Leave at door, ring bell, etc.'),
        ),
        const SizedBox(height: 28),
        AnimatedFadeSlide(
          delay: 250,
          duration: const Duration(milliseconds: 500),
          child: _buildSection(context, 'Fulfillment'),
        ),
        const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: 300,
          duration: const Duration(milliseconds: 500),
          child: Row(
            children: [
              Expanded(child: _fulfillmentTile(context, FulfillmentType.delivery, Icons.delivery_dining_rounded, 'Delivery')),
              const SizedBox(width: 12),
              Expanded(child: _fulfillmentTile(context, FulfillmentType.pickup, Icons.store_rounded, 'Pickup')),
            ],
          ),
        ),
        if (widget.fulfillment == FulfillmentType.delivery) ...[
          const SizedBox(height: 16),
          AnimatedFadeSlide(
            delay: 325,
            duration: const Duration(milliseconds: 500),
            child: _buildExpressToggle(context),
          ),
        ],
        if (widget.fulfillment == FulfillmentType.delivery) ...[
          const SizedBox(height: 16),
          AnimatedFadeSlide(
            delay: 335,
            duration: const Duration(milliseconds: 500),
            child: _buildScheduleToggle(context),
          ),
        ],
        const SizedBox(height: 28),
        if (widget.activeSubscription != null && widget.activeSubscription!.isActive)
          AnimatedFadeSlide(
            delay: 340,
            duration: const Duration(milliseconds: 500),
            child: _buildSubscriptionBanner(context),
          ),
        if (widget.activeSubscription != null && widget.activeSubscription!.isActive)
          const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: 350,
          duration: const Duration(milliseconds: 500),
          child: _buildSection(context, 'Order Summary'),
        ),
        const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: 400,
          duration: const Duration(milliseconds: 500),
          child: _buildSummaryCard(context),
        ),
        const SizedBox(height: 16),
        AnimatedFadeSlide(
          delay: 450,
          duration: const Duration(milliseconds: 500),
          child: _buildTipSection(context),
        ),
        const SizedBox(height: 28),
        AnimatedFadeSlide(
          delay: 500,
          duration: const Duration(milliseconds: 500),
          child: AnimatedPressScale(
            onTap: widget.onPlaceOrder,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: AppRadius.brLg,
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Place Order — \$${_effectiveTotal().toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primaryHover],
            ),
            borderRadius: AppRadius.brXs,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildField(BuildContext context, String label, IconData icon, TextEditingController ctrl, {int maxLines = 1, String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(
          color: context.textPrimaryColor,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: context.textMutedColor,
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, size: 20, color: context.textMutedColor),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _fulfillmentTile(BuildContext context, FulfillmentType type, IconData icon, String label) {
    final selected = widget.fulfillment == type;
    return AnimatedPressScale(
      onTap: () => widget.onFulfillmentChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? context.primaryColor.withValues(alpha: 0.1)
              : context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: selected
                ? context.primaryColor.withValues(alpha: 0.5)
                : context.borderColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? context.primaryColor.withValues(alpha: 0.15)
                    : context.surfaceAltColor,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                icon,
                color: selected ? context.primaryColor : context.textMutedColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? context.primaryColor : context.textMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressToggle(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onExpressChanged(!widget.isExpress),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isExpress
              ? AppColors.error.withValues(alpha: 0.08)
              : context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: widget.isExpress
                ? AppColors.error.withValues(alpha: 0.4)
                : context.borderColor.withValues(alpha: 0.3),
            width: widget.isExpress ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: widget.isExpress
                    ? LinearGradient(colors: [AppColors.error, Color(0xFFF87171)])
                    : null,
                color: widget.isExpress ? null : context.surfaceAltColor,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: widget.isExpress ? Colors.white : context.textMutedColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Express Delivery',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      if (!widget.isExpress) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Text(
                            '+\$2.00',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isExpress ? '15-25 min delivery' : 'Get your order 2x faster',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: widget.isExpress
                    ? AppColors.error
                    : context.surfaceAltColor,
                borderRadius: AppRadius.brMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: widget.isExpress ? Colors.white : context.textMutedColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: widget.isExpress ? Alignment.centerRight : Alignment.centerLeft,
                  child: widget.isExpress ? null : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleToggle(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.scheduledTime ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 7)),
        );
        if (picked != null && context.mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(widget.scheduledTime ?? DateTime.now().add(const Duration(hours: 1))),
          );
          if (time != null) {
            final scheduled = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
            widget.onScheduledTimeChanged(scheduled);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.scheduledTime != null
              ? AppColors.primary.withValues(alpha: 0.06)
              : context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: widget.scheduledTime != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : context.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.scheduledTime != null
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : context.surfaceAltColor,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: widget.scheduledTime != null ? AppColors.primary : context.textMutedColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Delivery',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.scheduledTime != null
                        ? '${_formatScheduledTime(widget.scheduledTime!)}'
                        : 'Choose a future date & time',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textMutedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatScheduledTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
  }

  Widget _buildTipSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tip for driver',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 14),
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
    final isSelected = _selectedTip == label;
    return Expanded(
      child: AnimatedPressScale(
        onTap: () => setState(() => _selectedTip = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.12)
                : context.surfaceAltColor,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: isSelected
                  ? context.primaryColor.withValues(alpha: 0.5)
                  : context.borderColor.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? context.primaryColor : context.textMutedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final effectiveDeliveryFee = widget.subscriptionFreeDelivery && widget.fulfillment == FulfillmentType.delivery
        ? 0.0
        : widget.cart.deliveryFee;
    final effectiveSubtotal = widget.cart.subtotal;
    final totalBeforeDiscount = effectiveSubtotal + effectiveDeliveryFee + widget.cart.tax;
    final effectiveTotal = (totalBeforeDiscount - widget.cart.promoDiscount - widget.subscriptionDiscount).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow(context, 'Items (${widget.cart.totalQuantity})', '\$${effectiveSubtotal.toStringAsFixed(2)}'),
          if (widget.subscriptionFreeDelivery && widget.fulfillment == FulfillmentType.delivery)
            _summaryRow(context, 'Delivery Fee', 'Free (Plus)', valueColor: context.successColor)
          else
            _summaryRow(context, 'Delivery Fee', widget.fulfillment == FulfillmentType.pickup ? 'Free' : '\$${effectiveDeliveryFee.toStringAsFixed(2)}'),
          _summaryRow(context, 'Tax', '\$${widget.cart.tax.toStringAsFixed(2)}'),
          if (widget.cart.promoDiscount > 0)
            _summaryRow(context, 'Promo Discount', '-\$${widget.cart.promoDiscount.toStringAsFixed(2)}', valueColor: context.successColor),
          if (widget.subscriptionDiscount > 0)
            _summaryRow(context, 'Plus Discount (${widget.activeSubscription!.plan.discountPercent.round()}% off)', '-\$${widget.subscriptionDiscount.toStringAsFixed(2)}', valueColor: context.successColor),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.borderColor.withValues(alpha: 0.4)),
          ),
          _summaryRow(context, 'Total', '\$${effectiveTotal.toStringAsFixed(2)}', bold: true),
          if (widget.subscriptionDiscount > 0 || widget.subscriptionFreeDelivery)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.savings_rounded, size: 14, color: context.successColor),
                  const SizedBox(width: 4),
                  Text(
                    'You saved \$${(widget.subscriptionDiscount + (widget.subscriptionFreeDelivery ? widget.cart.deliveryFee : 0)).toStringAsFixed(2)} with TayyebGo Plus',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.successColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: bold ? context.textPrimaryColor : context.textMutedColor,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? context.textPrimaryColor,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner(BuildContext context) {
    final planName = widget.activeSubscription!.plan.displayName;
    final discountPct = widget.activeSubscription!.plan.discountPercent.round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.8)],
              ),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TayyebGo $planName Benefits Applied',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$discountPct% discount${widget.subscriptionFreeDelivery ? ' + Free delivery' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: context.successColor, size: 22),
        ],
      ),
    );
  }
}

class _ProcessingState extends StatefulWidget {
  const _ProcessingState();

  @override
  State<_ProcessingState> createState() => _ProcessingStateState();
}

class _ProcessingStateState extends State<_ProcessingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primaryColor.withValues(alpha: 0.2),
                      context.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: context.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Processing your order',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: context.textPrimaryColor,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we confirm your order...',
              style: GoogleFonts.inter(
                color: context.textMutedColor,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: context.primaryColor,
              ),
            ),
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
            AnimatedScaleIn(
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.errorColor.withValues(alpha: 0.2),
                      context.errorColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.errorColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: context.errorColor,
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedFadeSlide(
              delay: 100,
              child: Text(
                'Order Failed',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: context.textPrimaryColor,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedFadeSlide(
              delay: 200,
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: context.textMutedColor,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedFadeSlide(
              delay: 300,
              child: AnimatedPressScale(
                onTap: onRetry,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: AppRadius.brLg,
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Try Again',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedFadeSlide(
              delay: 400,
              child: AnimatedPressScale(
                onTap: () => context.pop(),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.surfaceAltColor,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(
                      color: context.borderColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back to Cart',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.textMutedColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
