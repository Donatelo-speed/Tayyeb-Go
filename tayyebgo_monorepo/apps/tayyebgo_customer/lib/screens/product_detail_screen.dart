import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String restaurantId;
  final String restaurantName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String _notes = '';
  final List<Map<String, dynamic>> _selectedModifiers = [];
  double _totalPrice = 0;
  Map<String, dynamic>? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menu_items')
          .doc(widget.productId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _product = data;
          _totalPrice = (data['price'] as num?)?.toDouble() ?? 0;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateTotal() {
    if (_product == null) return;
    double base = (_product!['price'] as num?)?.toDouble() ?? 0;
    for (final mod in _selectedModifiers) {
      base += (mod['price'] as num?)?.toDouble() ?? 0;
    }
    setState(() => _totalPrice = base * _quantity);
  }

  void _addToCart() {
    if (_product == null) return;
    final cart = context.read<CartProvider>();

    final product = Product(
      id: 0,
      firestoreId: widget.productId,
      name: _product!['name'] ?? '',
      price: (_product!['price'] as num?)?.toDouble() ?? 0,
      imageUrl: _product!['imageUrl'] as String?,
      restaurantId: widget.restaurantId,
      isAvailable: _product!['isAvailable'] ?? true,
      description: _product!['description'] as String?,
      category: _product!['category'] as String? ?? '',
    );

    cart.addLine(
      product,
      quantity: _quantity,
      customerNote: _notes.isNotEmpty ? _notes : null,
    );

    TGHaptics.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_product!['name']} added to cart'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: TGEmptyState(
          icon: Icons.fastfood_rounded,
          title: 'Product not found',
          description: 'This item may no longer be available.',
        ),
      );
    }

    final name = _product!['name'] ?? '';
    final description = _product!['description'] ?? '';
    final price = (_product!['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = _product!['imageUrl'] as String?;
    final isAvailable = _product!['isAvailable'] ?? true;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: context.backgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null && imageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: context.surfaceColor,
                            child: Icon(
                              Icons.fastfood_rounded,
                              size: 64,
                              color: context.textMutedColor,
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: context.surfaceColor,
                      child: Icon(
                        Icons.fastfood_rounded,
                        size: 64,
                        color: context.textMutedColor,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Unavailable',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.restaurantName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SYP ${price.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: context.textMutedColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildQuantitySelector(),
                  const SizedBox(height: 24),
                  _buildNotesField(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isAvailable ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_rounded, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Add to Cart — SYP ${_totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Quantity',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              _qtyBtn(Icons.remove_rounded, () {
                if (_quantity > 1) {
                  setState(() => _quantity--);
                  _updateTotal();
                }
              }),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              _qtyBtn(Icons.add_rounded, () {
                setState(() => _quantity++);
                _updateTotal();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Instructions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          onChanged: (v) => setState(() => _notes = v),
          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'e.g. No onions, extra sauce...',
            hintStyle: GoogleFonts.inter(color: context.textMutedColor),
            filled: true,
            fillColor: context.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
