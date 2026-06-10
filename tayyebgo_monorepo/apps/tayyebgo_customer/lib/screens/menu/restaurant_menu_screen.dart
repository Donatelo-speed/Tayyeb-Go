import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final double commissionPercent;

  const RestaurantMenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.commissionPercent = AppConstants.commissionPercent,
  });

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _selectedCategory;
  final GlobalKey _cartIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().setRestaurant(
          widget.restaurantId,
          widget.restaurantName,
          commissionPercent: widget.commissionPercent,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(widget.restaurantName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: _cartIconKey,
                icon: Icon(Icons.shopping_cart_outlined, color: context.textMutedColor),
                onPressed: () => context.go('/cart'),
              ),
              Consumer<CartProvider>(
                builder: (_, cart, __) {
                  if (cart.isEmpty) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: context.primaryColor, shape: BoxShape.circle),
                      child: Text('${cart.totalQuantity}', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<CustomerHomeProvider>().watchMenuItems(widget.restaurantId),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                  const SizedBox(height: 12),
                  Text('Failed to load menu', style: GoogleFonts.inter(color: context.textMutedColor)),
                ],
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.primaryColor));
          }
          final docs = snap.data ?? [];
          if (docs.isEmpty) {
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
                    child: Icon(Icons.restaurant_menu_outlined, size: 36, color: context.textMutedColor),
                  ),
                  const SizedBox(height: 16),
                  Text('Menu not available', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final items = docs.map((d) => Product.fromJson({...d, 'firestoreId': d['id']})).toList();
          final categories = <String, List<Product>>{};
          for (final item in items) {
            categories.putIfAbsent(item.category, () => []);
            categories[item.category]!.add(item);
          }
          final catNames = categories.keys.toList();

          final filteredItems = _searchQuery.isEmpty
              ? items
              : items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search menu...',
                      hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.textMutedColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: context.textMutedColor),
                              onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              if (_searchQuery.isEmpty && catNames.length > 1)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: catNames.length,
                    itemBuilder: (_, i) {
                      final cat = catNames[i];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? context.primaryColor : context.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? context.primaryColor : context.borderColor,
                            ),
                          ),
                          child: Text(
                            cat.isEmpty ? 'All' : cat,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : context.textMutedColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildItemList(context, filteredItems)
                    : _buildCategorizedList(context, categories, catNames),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemList(BuildContext context, List<Product> items) {
    if (items.isEmpty) {
      return Center(child: Text('No items found', style: GoogleFonts.inter(color: context.textMutedColor)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => _MenuItemCard(
        product: items[i],
        restaurantId: widget.restaurantId,
        commissionPercent: widget.commissionPercent,
        cartIconKey: _cartIconKey,
      ),
    );
  }

  Widget _buildCategorizedList(BuildContext context, Map<String, List<Product>> categories, List<String> catNames) {
    final displayCats = _selectedCategory != null
        ? catNames.where((c) => c == _selectedCategory).toList()
        : catNames;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayCats.length,
      itemBuilder: (_, i) {
        final cat = displayCats[i];
        final catItems = categories[cat]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cat.isEmpty ? 'Other Items' : cat,
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${catItems.length}',
                    style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor),
                  ),
                ],
              ),
            ),
            ...catItems.map((item) => _MenuItemCard(
              product: item,
              restaurantId: widget.restaurantId,
              commissionPercent: widget.commissionPercent,
              cartIconKey: _cartIconKey,
            )),
          ],
        );
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final Product product;
  final String restaurantId;
  final double commissionPercent;
  final GlobalKey? cartIconKey;

  const _MenuItemCard({
    required this.product,
    required this.restaurantId,
    required this.commissionPercent,
    this.cartIconKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showItemDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
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
                    product.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor),
                  ),
                  if (product.description != null && product.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        product.description!,
                        style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.primaryColor),
                  ),
                ],
              ),
            ),
            if (product.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  product.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: context.surfaceAltColor,
                    child: Icon(Icons.restaurant, color: context.textMutedColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItemDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(
        product: product,
        restaurantId: restaurantId,
        commissionPercent: commissionPercent,
        cartIconKey: cartIconKey,
      ),
    );
  }
}

class _ItemDetailSheet extends StatefulWidget {
  final Product product;
  final String restaurantId;
  final double commissionPercent;
  final GlobalKey? cartIconKey;

  const _ItemDetailSheet({
    required this.product,
    required this.restaurantId,
    required this.commissionPercent,
    this.cartIconKey,
  });

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  int _quantity = 1;
  final Map<String, List<String>> _selectedOptions = {};
  String _note = '';

  @override
  void initState() {
    super.initState();
    for (final group in widget.product.modifierGroups ?? []) {
      final defaults = group.options.where((o) => o.isDefault).map((o) => o.id).toList();
      if (defaults.isNotEmpty) _selectedOptions[group.id] = defaults;
    }
  }

  double get _modifiersTotal {
    double total = 0;
    for (final group in widget.product.modifierGroups ?? []) {
      final selected = _selectedOptions[group.id] ?? [];
      for (final optId in selected) {
        final opt = group.options.where((o) => o.id == optId).firstOrNull;
        if (opt != null) total += opt.priceAdjustment;
      }
    }
    return total;
  }

  double get _unitPrice => widget.product.price + _modifiersTotal;
  double get _lineTotal => _unitPrice * _quantity;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.product.name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22, color: context.textPrimaryColor),
              ),
              if (widget.product.description != null && widget.product.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(widget.product.description!, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
                ),
              const SizedBox(height: 12),
              Text(
                '\$${widget.product.price.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24, color: context.primaryColor),
              ),
              const SizedBox(height: 20),
              if (widget.product.modifierGroups != null && widget.product.modifierGroups!.isNotEmpty)
                ...widget.product.modifierGroups!.map((group) => _ModifierGroupSelector(
                  group: group,
                  selected: _selectedOptions[group.id] ?? [],
                  onChanged: (ids) => setState(() => _selectedOptions[group.id] = ids),
                )),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: TextField(
                  maxLines: 2,
                  style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
                  onChanged: (v) => _note = v,
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QtyBtn(
                          icon: Icons.remove_rounded,
                          onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_quantity',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor),
                          ),
                        ),
                        _QtyBtn(
                          icon: Icons.add_rounded,
                          onTap: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${_lineTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: context.textPrimaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final selectedMods = (widget.product.modifierGroups ?? []).map((g) {
                      return SelectedModifierGroup(
                        groupId: g.id,
                        groupName: g.name,
                        selectedOptionIds: _selectedOptions[g.id] ?? [],
                        group: g,
                      );
                    }).toList();
                    cart.addLine(
                      widget.product,
                      quantity: _quantity,
                      modifiers: selectedMods,
                      customerNote: _note.isEmpty ? null : _note,
                    );

                    // Fly-to-cart animation
                    final cartKey = widget.cartIconKey;
                    if (cartKey != null && cartKey.currentContext != null) {
                      final cartBox = cartKey.currentContext!.findRenderObject() as RenderBox?;
                      if (cartBox != null) {
                        final cartPos = cartBox.localToGlobal(cartBox.size.center(Offset.zero));
                        final overlay = Overlay.of(context);
                        late OverlayEntry entry;
                        entry = OverlayEntry(
                          builder: (_) => _FlyToCartOverlay(
                            start: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 100),
                            end: cartPos,
                            onComplete: () => entry.remove(),
                          ),
                        );
                        overlay.insert(entry);
                      }
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add to Cart — \$${_lineTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay that animates a small circular dot from [start] to [end].
class _FlyToCartOverlay extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;

  const _FlyToCartOverlay({
    required this.start,
    required this.end,
    required this.onComplete,
  });

  @override
  State<_FlyToCartOverlay> createState() => _FlyToCartOverlayState();
}

class _FlyToCartOverlayState extends State<_FlyToCartOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _posAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _posAnim = Tween<Offset>(begin: widget.start, end: widget.end).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.2), weight: 70),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final pos = _posAnim.value;
        return Positioned(
          left: pos.dx - 16,
          top: pos.dy - 16,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? context.surfaceAltColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? context.textPrimaryColor : context.textMutedColor,
        ),
      ),
    );
  }
}

class _ModifierGroupSelector extends StatelessWidget {
  final ModifierGroup group;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _ModifierGroupSelector({
    required this.group,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor),
              ),
              if (group.required) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Required', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: context.errorColor)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...group.options.map((opt) {
            final isSelected = selected.contains(opt.id);
            final disabled = !isSelected && selected.length >= group.maxSelections;
            return GestureDetector(
              onTap: disabled
                  ? null
                  : () {
                      if (isSelected) {
                        onChanged(List.from(selected)..remove(opt.id));
                      } else {
                        if (group.maxSelections == 1) {
                          onChanged([opt.id]);
                        } else {
                          onChanged(List.from(selected)..add(opt.id));
                        }
                      }
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? context.primaryColor.withValues(alpha: 0.1) : context.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? context.primaryColor.withValues(alpha: 0.3) : context.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      group.maxSelections == 1
                          ? (isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded)
                          : (isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded),
                      size: 20,
                      color: isSelected ? context.primaryColor : context.textMutedColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opt.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: disabled ? context.textMutedColor : context.textPrimaryColor,
                        ),
                      ),
                    ),
                    if (opt.priceAdjustment > 0)
                      Text(
                        '+\$${opt.priceAdjustment.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.primaryColor),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
