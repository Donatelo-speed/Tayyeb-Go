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
      appBar: AppBar(
        title: Text('Your Cart', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => cart.clearCart(),
              child: Text('Clear', style: GoogleFonts.inter(color: context.errorColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Cart is empty',
              subtitle: 'Browse restaurants and add items',
              actionText: 'Browse Restaurants',
              onAction: () => context.push('/home'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.lines.length + 1,
                    itemBuilder: (_, i) {
                      if (i == cart.lines.length) return _CartSummary(cart: cart);
                      final line = cart.lines[i];
                      return _CartItemRow(line: line, cart: cart);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.push('/checkout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Checkout — \$${cart.grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: context.errorColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor),
                  ),
                  if (line.selectedModifiers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        line.selectedModifiers
                            .expand((g) => g.selectedOptionIds.map((oid) {
                              final opt = g.group.options.where((o) => o.id == oid).firstOrNull;
                              return opt?.name ?? oid;
                            }))
                            .join(', '),
                        style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (line.customerNote != null && line.customerNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '"${line.customerNote}"',
                        style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${line.unitPrice.toStringAsFixed(2)} each',
                    style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => cart.decrementLine(line.lineId),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${line.quantity}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor),
                    ),
                  ),
                  _QtyBtn(
                    icon: Icons.add_rounded,
                    onTap: () => cart.incrementLine(line.lineId),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '\$${line.lineTotal.toStringAsFixed(2)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.surfaceAltColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: context.textPrimaryColor),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal (${cart.totalQuantity} items)', '\$${cart.subtotal.toStringAsFixed(2)}'),
          _row(context, 'Delivery Fee', cart.deliveryFee == 0 ? 'Free' : '\$${cart.deliveryFee.toStringAsFixed(2)}', valueColor: cart.deliveryFee == 0 ? context.successColor : null),
          _row(context, 'Tax', '\$${cart.tax.toStringAsFixed(2)}'),
          if (cart.promoDiscount > 0) ...[
            _row(context, 'Discount', '-\$${cart.promoDiscount.toStringAsFixed(2)}', valueColor: context.successColor),
            _row(context, 'Coupon', cart.appliedCoupon ?? ''),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.borderColor),
          ),
          _row(context, 'Total', '\$${cart.grandTotal.toStringAsFixed(2)}', bold: true),
          const SizedBox(height: 12),
          _CouponSection(cart: cart),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: bold ? context.textPrimaryColor : context.textMutedColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? context.textPrimaryColor,
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
      return Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: context.successColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Coupon "${widget.cart.appliedCoupon}" applied',
              style: GoogleFonts.inter(color: context.successColor, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.cart.removeCoupon();
              _ctrl.clear();
              _error = null;
            },
            child: Text('Remove', style: GoogleFonts.inter(color: context.errorColor, fontSize: 13)),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _error != null ? context.errorColor.withValues(alpha: 0.5) : context.borderColor,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Coupon code',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
                prefixIcon: Icon(Icons.local_offer_rounded, size: 18, color: context.textMutedColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                errorText: _error,
                errorStyle: GoogleFonts.inter(fontSize: 11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _loading ? null : _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.surfaceAltColor,
              foregroundColor: context.textPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _loading
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor))
                : Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
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
    if (mounted) setState(() {
      _loading = false;
      _error = err;
    });
  }
}
