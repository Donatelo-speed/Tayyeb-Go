import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return AppScaffold(
      title: 'Your Cart',
      body: cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Cart is empty',
              subtitle:
                  'Browse restaurants and add items to get started',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: cart.lines.length + 1,
                    itemBuilder: (_, i) {
                      if (i == cart.lines.length) {
                        return _CartSummary(
                            cart: cart);
                      }
                      final line = cart.lines[i];
                      return _CartItemRow(
                          line: line, cart: cart);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(
                            top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset:
                            const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.go('/checkout'),
                        style:
                            ElevatedButton.styleFrom(
                          padding: const EdgeInsets
                              .symmetric(vertical: 14),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),
                        child: Text(
                            'Checkout — \$${cart.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w600)),
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

  const _CartItemRow(
      {required this.line, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(line.product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                if (line.selectedModifiers.isNotEmpty)
                  Text(
                    line.selectedModifiers
                        .expand((g) => g.selectedOptionIds
                            .map((oid) {
                          final opt = g.group.options
                              .where((o) => o.id == oid)
                              .firstOrNull;
                          return opt?.name ?? oid;
                        }))
                        .join(', '),
                    style: TayyebGoTheme.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (line.customerNote != null &&
                    line.customerNote!.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 2),
                    child: Text(
                        '"${line.customerNote}"',
                        style: TextStyle(
                            fontSize: 11,
                            color: TayyebGoTheme
                                .textSecondary,
                            fontStyle: FontStyle
                                .italic)),
                  ),
                Text(
                    '\$${line.unitPrice.toStringAsFixed(2)} each',
                    style: TextStyle(
                        fontSize: 12,
                        color: TayyebGoTheme
                            .textSecondary)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(10),
              color: const Color(0xFFF8FAFC),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyBtn(
                  icon: Icons.remove_rounded,
                  onPressed: () =>
                      cart.decrementLine(line.lineId),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12),
                  child: Text('${line.quantity}',
                      style: const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 14)),
                ),
                _QtyBtn(
                  icon: Icons.add_rounded,
                  onPressed: () =>
                      cart.incrementLine(line.lineId),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 68,
            child: Text(
                '\$${line.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
                textAlign: TextAlign.right),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 16),
            onPressed: () =>
                cart.removeLine(line.lineId),
            color: TayyebGoTheme.textMuted,
            constraints: const BoxConstraints(
                minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _QtyBtn(
      {required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 16,
            color: TayyebGoTheme.textPrimary),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _row(
              'Subtotal (${cart.totalQuantity} items)',
              '\$${cart.subtotal.toStringAsFixed(2)}'),
          _row(
              'Delivery Fee',
              cart.deliveryFee == 0
                  ? 'Free'
                  : '\$${cart.deliveryFee.toStringAsFixed(2)}'),
          _row('Tax',
              '\$${cart.tax.toStringAsFixed(2)}'),
          if (cart.promoDiscount > 0) ...[
            _row('Discount',
                '-\$${cart.promoDiscount.toStringAsFixed(2)}',
                valueColor:
                    TayyebGoTheme.successColor),
            _row('Coupon',
                cart.appliedCoupon ?? ''),
          ],
          const Divider(height: 22),
          _row('Total',
              '\$${cart.grandTotal.toStringAsFixed(2)}',
              bold: true),
          const SizedBox(height: 12),
          _CouponSection(cart: cart),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color:
                        TayyebGoTheme.textSecondary,
                    fontWeight: bold
                        ? FontWeight.w600
                        : FontWeight.w400)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: valueColor)),
          ]),
    );
  }
}

class _CouponSection extends StatefulWidget {
  final CartProvider cart;
  const _CouponSection({required this.cart});

  @override
  State<_CouponSection> createState() =>
      _CouponSectionState();
}

class _CouponSectionState
    extends State<_CouponSection> {
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
          Icon(Icons.check_circle_rounded,
              size: 16,
              color:
                  TayyebGoTheme.successColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                'Coupon "${widget.cart.appliedCoupon}" applied',
                style: TextStyle(
                    color: TayyebGoTheme
                        .successColor,
                    fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              widget.cart.removeCoupon();
              _ctrl.clear();
              _error = null;
            },
            child: const Text('Remove',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10),
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                textCapitalization:
                    TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed:
                    _loading ? null : _apply,
                style:
                    ElevatedButton.styleFrom(
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            10),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                                strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _apply() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.cart
        .applyCoupon(_ctrl.text);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }
}