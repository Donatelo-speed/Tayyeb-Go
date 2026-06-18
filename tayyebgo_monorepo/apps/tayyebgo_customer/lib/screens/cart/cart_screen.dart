import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
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
                    Expanded(
                      child: Text(
                        'Your Cart',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          color: context.textPrimaryColor,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (!cart.isEmpty)
                      AnimatedPressScale(
                        onTap: () => cart.clearCart(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.errorColor.withValues(alpha: 0.08),
                            borderRadius: AppRadius.brMd,
                          ),
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              color: context.errorColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: cart.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Cart is empty',
                      subtitle: 'Browse restaurants and add items',
                      actionText: 'Browse Restaurants',
                      onAction: () => context.push('/home'),
                      accentColor: context.primaryColor,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cart.lines.length + 1,
                      itemBuilder: (_, i) {
                        if (i == cart.lines.length) {
                          return AnimatedFadeSlide(
                            delay: (cart.lines.length * 50).toDouble(),
                            duration: const Duration(milliseconds: 400),
                            child: _CartSummary(cart: cart),
                          );
                        }
                        final line = cart.lines[i];
                        return AnimatedFadeSlide(
                          delay: (i * 50).toDouble(),
                          duration: const Duration(milliseconds: 400),
                          child: _CartItemRow(line: line, cart: cart),
                        );
                      },
                    ),
            ),
            if (!cart.isEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: context.borderColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: AnimatedPressScale(
                    onTap: () => context.push('/checkout'),
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
                          'Checkout — \$${cart.grandTotal.toStringAsFixed(2)}',
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
              ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartLineItem line;
  final CartProvider cart;

  const _CartItemRow({required this.line, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(line.lineId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.removeLine(line.lineId),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.errorColor.withValues(alpha: 0.8),
              context.errorColor,
            ],
          ),
          borderRadius: AppRadius.brCard,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brCard,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.4),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textPrimaryColor,
                      letterSpacing: 0,
                    ),
                  ),
                  if (line.selectedModifiers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        line.selectedModifiers
                            .expand((g) => g.selectedOptionIds.map((oid) {
                              final opt = g.group.options.where((o) => o.id == oid).firstOrNull;
                              return opt?.name ?? oid;
                            }))
                            .join(', '),
                        style: GoogleFonts.inter(
                          color: context.textMutedColor,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (line.customerNote != null && line.customerNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '"${line.customerNote}"',
                        style: GoogleFonts.inter(
                          color: context.textMutedColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${line.unitPrice.toStringAsFixed(2)} each',
                    style: GoogleFonts.inter(
                      color: context.textMutedColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.surfaceAltColor,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => cart.decrementLine(line.lineId),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '${line.quantity}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  _QtyBtn(
                    icon: Icons.add_rounded,
                    onTap: () => cart.incrementLine(line.lineId),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '\$${line.lineTotal.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.textPrimaryColor,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedPressScale(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 18, color: context.textPrimaryColor),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.4),
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
          _row(
            context,
            'Subtotal (${cart.totalQuantity} items)',
            '\$${cart.subtotal.toStringAsFixed(2)}',
          ),
          _row(
            context,
            'Delivery Fee',
            cart.deliveryFee == 0 ? 'Free' : '\$${cart.deliveryFee.toStringAsFixed(2)}',
            valueColor: cart.deliveryFee == 0 ? context.successColor : null,
          ),
          _row(context, 'Tax', '\$${cart.tax.toStringAsFixed(2)}'),
          if (cart.promoDiscount > 0) ...[
            _row(
              context,
              'Discount',
              '-\$${cart.promoDiscount.toStringAsFixed(2)}',
              valueColor: context.successColor,
            ),
            _row(context, 'Coupon', cart.appliedCoupon ?? ''),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.borderColor.withValues(alpha: 0.4)),
          ),
          _row(
            context,
            'Total',
            '\$${cart.grandTotal.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 16),
          _CouponSection(cart: cart),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: bold ? context.textPrimaryColor : context.textMutedColor,
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
}

class _CouponSection extends StatefulWidget {
  final CartProvider cart;
  const _CouponSection({required this.cart});

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cart.appliedCoupon != null) {
      return AnimatedFadeSlide(
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.successColor.withValues(alpha: 0.08),
            borderRadius: AppRadius.brMd,
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: context.successColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coupon "${widget.cart.appliedCoupon}" applied',
                  style: GoogleFonts.inter(
                    color: context.successColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              AnimatedPressScale(
                onTap: () {
                  widget.cart.removeCoupon();
                  _ctrl.clear();
                  setState(() => _error = null);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.errorColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.brButton,
                  ),
                  child: Text(
                    'Remove',
                    style: GoogleFonts.inter(
                      color: context.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: _error != null
                    ? context.errorColor.withValues(alpha: 0.5)
                    : context.borderColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              style: GoogleFonts.inter(
                color: context.textPrimaryColor,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Coupon code',
                hintStyle: GoogleFonts.inter(
                  color: context.textMutedColor,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.local_offer_rounded,
                    size: 18,
                    color: context.textMutedColor,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                errorText: _error,
                errorStyle: GoogleFonts.inter(fontSize: 11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedPressScale(
          onTap: _loading ? null : _apply,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: AppRadius.brMd,
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _apply() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.cart.applyCoupon(_ctrl.text);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }
}
