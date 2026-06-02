import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    this.commissionPercent = 15.0,
  });

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
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
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.restaurantName,
      showCart: true,
      body: StreamScreenBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menu_items')
            .where('restaurantId', isEqualTo: widget.restaurantId)
            .where('isAvailable', isEqualTo: true)
            .snapshots(),
        onLoading: () => const ShimmerLoading(itemCount: 6),
        onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
        onSuccess: (ctx, snap) {
          if (snap.docs.isEmpty) {
            return const EmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: 'Menu not available',
              subtitle: 'This restaurant has no items listed yet',
            );
          }
          final items = snap.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return Product.fromJson({...d, 'firestoreId': doc.id});
          }).toList();
          final categories = <String, List<Product>>{};
          for (final item in items) {
            categories.putIfAbsent(item.category, () => []);
            categories[item.category]!.add(item);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: categories.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      entry.key.isEmpty ? 'Menu Items' : entry.key,
                      style: TayyebGoTheme.heading3,
                    ),
                  ),
                  ...entry.value.map((item) => _MenuItemCard(
                        product: item,
                        restaurantId: widget.restaurantId,
                        commissionPercent: widget.commissionPercent,
                      )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final Product product;
  final String restaurantId;
  final double commissionPercent;

  const _MenuItemCard({
    required this.product,
    required this.restaurantId,
    required this.commissionPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: TayyebGoTheme.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
        onTap: () => _showItemDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (product.description != null && product.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(product.description!, style: TayyebGoTheme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    const SizedBox(height: 6),
                    Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor)),
                  ],
                ),
              ),
              if (product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(product.imageUrl!, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ItemDetailSheet(
        product: product,
        restaurantId: restaurantId,
        commissionPercent: commissionPercent,
      ),
    );
  }
}

class _ItemDetailSheet extends StatefulWidget {
  final Product product;
  final String restaurantId;
  final double commissionPercent;

  const _ItemDetailSheet({
    required this.product,
    required this.restaurantId,
    required this.commissionPercent,
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
      if (defaults.isNotEmpty) {
        _selectedOptions[group.id] = defaults;
      }
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TayyebGoTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.product.name, style: TayyebGoTheme.heading2),
          if (widget.product.description != null && widget.product.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(widget.product.description!, style: TayyebGoTheme.body),
            ),
          const SizedBox(height: 16),
          Text('\$${widget.product.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor)),
          const SizedBox(height: 20),
          if (widget.product.modifierGroups != null && widget.product.modifierGroups!.isNotEmpty)
            ...widget.product.modifierGroups!.map((group) => _ModifierGroupSelector(
                  group: group,
                  selected: _selectedOptions[group.id] ?? [],
                  onChanged: (ids) => setState(() => _selectedOptions[group.id] = ids),
                )),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(hintText: 'Add a note...', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
            maxLines: 2,
            onChanged: (v) => _note = v,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: TayyebGoTheme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text('\$${_lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) Navigator.pop(context);
                });
              },
              child: Text('Add to Cart — \$${_lineTotal.toStringAsFixed(2)}'),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.required ? '${group.name} *' : group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...group.options.map((opt) {
            final isSelected = selected.contains(opt.id);
            final disabled = !isSelected && selected.length >= group.maxSelections;
            return InkWell(
              onTap: disabled ? null : () {
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      group.maxSelections == 1
                          ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_off)
                          : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                      size: 20,
                      color: isSelected ? TayyebGoTheme.primaryColor : TayyebGoTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(opt.name, style: TextStyle(color: disabled ? TayyebGoTheme.textMuted : TayyebGoTheme.textPrimary))),
                    if (opt.priceAdjustment > 0)
                      Text('+\$${opt.priceAdjustment.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: TayyebGoTheme.primaryColor)),
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
