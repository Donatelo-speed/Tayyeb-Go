import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ReorderScreen extends StatelessWidget {
  final String orderId;

  const ReorderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Reorder',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load order',
                    style: GoogleFonts.inter(color: context.textMutedColor),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.primaryColor));
          }
          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Icon(Icons.receipt_long_outlined, size: 36, color: context.textMutedColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order not found',
                    style: GoogleFonts.inter(
                      color: context.textMutedColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = doc.data() as Map<String, dynamic>;
          final items = (data['items'] as List<dynamic>?) ?? [];
          final restaurantName = data['restaurantName'] as String? ?? 'Restaurant';
          final restaurantId = data['restaurantId'] as String? ?? '';
          final createdAt = data['createdAt'] as Timestamp?;
          final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OrderHeader(
                      restaurantName: restaurantName,
                      createdAt: createdAt?.toDate(),
                      totalAmount: totalAmount,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order Items',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) => _OrderItemRow(item: item as Map<String, dynamic>)),
                    const SizedBox(height: 16),
                    _OrderTotalRow(total: totalAmount),
                  ],
                ),
              ),
              _ReorderButton(
                onPressed: () => _reorderAll(context, items, restaurantId, restaurantName),
              ),
            ],
          );
        },
      ),
    );
  }

  void _reorderAll(
    BuildContext context,
    List<dynamic> items,
    String restaurantId,
    String restaurantName,
  ) {
    final cart = context.read<CartProvider>();
    cart.setRestaurant(restaurantId, restaurantName);

    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      final name = item['name'] as String? ?? '';
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final price = (item['price'] as num?)?.toDouble() ?? 0;

      final product = Product(
        id: item['productId'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        name: name,
        price: price,
        restaurantId: restaurantId,
      );

      cart.addLine(product, quantity: quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${items.length} item(s) added to cart',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );

    context.push('/cart');
  }
}

class _OrderHeader extends StatelessWidget {
  final String restaurantName;
  final DateTime? createdAt;
  final double totalAmount;

  const _OrderHeader({
    required this.restaurantName,
    this.createdAt,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_rounded, color: context.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  createdAt != null
                      ? '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}'
                      : '',
                  style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? '';
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final unitPrice = (item['price'] as num?)?.toDouble() ?? 0;
    final subtotal = unitPrice * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity  x  \$${unitPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${subtotal.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTotalRow extends StatelessWidget {
  final double total;

  const _OrderTotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Order Total',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: context.textPrimaryColor,
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReorderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReorderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
            label: Text(
              'Reorder All',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
