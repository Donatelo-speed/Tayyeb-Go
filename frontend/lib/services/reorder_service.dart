import 'package:flutter/material.dart';

class ReorderResult {
  final bool canReorder;
  final bool isRestaurantOpen;
  final bool areItemsAvailable;
  final bool hasPriceChanges;
  final List<PriceChange> priceChanges;
  final List<CartItem> cartItems;
  final String? errorMessage;

  ReorderResult({
    required this.canReorder,
    this.isRestaurantOpen = true,
    this.areItemsAvailable = true,
    this.hasPriceChanges = false,
    this.priceChanges = const [],
    this.cartItems = const [],
    this.errorMessage,
  });
}

class PriceChange {
  final String itemName;
  final double oldPrice;
  final double newPrice;
  final bool available;

  PriceChange({
    required this.itemName,
    required this.oldPrice,
    required this.newPrice,
    this.available = true,
  });
}

class ReorderService {
  // Check if reorder is possible
  static Future<ReorderResult> validateReorder({
    required String restaurantId,
    required Order previousOrder,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Check 1: Is restaurant currently open?
      final isOpen = await _checkRestaurantOpen(restaurantId);
      if (!isOpen) {
        return ReorderResult(
          canReorder: false,
          isRestaurantOpen: false,
          errorMessage: 'Restaurant is currently closed',
        );
      }

      // Check 2: Are items still available?
      final itemCheck = await _checkItemsAvailability(
        restaurantId,
        previousOrder.items,
      );

      if (!itemCheck.allAvailable) {
        return ReorderResult(
          canReorder: false,
          isRestaurantOpen: true,
          areItemsAvailable: false,
          errorMessage:
              'Some items from your previous order are no longer available',
        );
      }

      // Check 3: Has price changed?
      final priceChanges = await _checkPriceChanges(previousOrder.items);

      final hasChanges = priceChanges.any((p) => p.newPrice != p.oldPrice);

      // Build cart items with current prices
      final cartItems = previousOrder.items.map((item) {
        final priceChange = priceChanges.firstWhere(
          (p) => p.itemName == item.productName,
          orElse: () => PriceChange(
            itemName: item.productName ?? '',
            oldPrice: item.unitPrice,
            newPrice: item.unitPrice,
          ),
        );

        return CartItem(
          productId: item.productId ?? '',
          name: item.productName ?? '',
          price: priceChange.newPrice,
          quantity: item.quantity,
          modifiers: _parseModifiers(item.selectedModifiers),
          customRequest: item.customRequest,
        );
      }).toList();

      return ReorderResult(
        canReorder: true,
        isRestaurantOpen: true,
        areItemsAvailable: true,
        hasPriceChanges: hasChanges,
        priceChanges: priceChanges,
        cartItems: cartItems,
      );
    } catch (e) {
      return ReorderResult(
        canReorder: false,
        errorMessage: 'Failed to validate reorder: $e',
      );
    }
  }

  // Simulate checking restaurant open status
  static Future<bool> _checkRestaurantOpen(String restaurantId) async {
    // In production: Call API to get restaurant status
    // final response = await ApiService.get('/restaurants/$restaurantId/status');
    // return response['isOpen'] ?? false;

    // Demo: Always return true
    return true;
  }

  // Check if items are still on menu
  static Future<ItemsAvailabilityResult> _checkItemsAvailability(
    String restaurantId,
    List<OrderItem> items,
  ) async {
    // In production: Call API to verify each item is still available
    // For demo: Check all items

    return ItemsAvailabilityResult(allAvailable: true);
  }

  // Check for price changes
  static Future<List<PriceChange>> _checkPriceChanges(
    List<OrderItem> items,
  ) async {
    // In production: Call API to get current prices and compare

    // Demo: Randomly change some prices for demonstration
    final changes = <PriceChange>[];

    for (final item in items) {
      // 20% chance of price change for demo
      final hasChange = DateTime.now().millisecond % 5 == 0;

      if (hasChange) {
        final newPrice =
            item.unitPrice * (0.9 + (DateTime.now().millisecond % 20) / 100);
        changes.add(
          PriceChange(
            itemName: item.productName ?? '',
            oldPrice: item.unitPrice,
            newPrice: newPrice,
          ),
        );
      }
    }

    return changes;
  }

  // Parse modifiers from JSON
  static List<SelectedModifier> _parseModifiers(dynamic modifiersJson) {
    if (modifiersJson == null) return [];

    try {
      if (modifiersJson is List) {
        return modifiersJson
            .map(
              (m) => SelectedModifier(
                groupName: m['groupName'] ?? '',
                optionName: m['optionName'] ?? '',
                price: (m['price'] ?? 0).toDouble(),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error parsing modifiers: $e');
    }

    return [];
  }
}

class ItemsAvailabilityResult {
  final bool allAvailable;
  final List<String> unavailableItems;

  ItemsAvailabilityResult({
    required this.allAvailable,
    this.unavailableItems = const [],
  });
}

// =====================================================
// REORDER WIDGET
// =====================================================

class OneTapReorderWidget extends StatelessWidget {
  final Order? lastCompletedOrder;
  final Function(List<CartItem>) onAddToCart;

  const OneTapReorderWidget({
    super.key,
    this.lastCompletedOrder,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    if (lastCompletedOrder == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.replay, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Reorder from last order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Order summary
          Text(
            lastCompletedOrder!.items
                .map((i) => '${i.quantity}x ${i.productName}')
                .join(', '),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 4),

          Text(
            'Total: ${lastCompletedOrder!.totalAmount} SYP',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 12),

          // Reorder button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleReorder(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('One-Tap Reorder'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReorder(BuildContext context) async {
    if (lastCompletedOrder == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Validate reorder
    final result = await ReorderService.validateReorder(
      restaurantId: lastCompletedOrder!.restaurantId,
      previousOrder: lastCompletedOrder!,
    );

    // Close loading
    if (context.mounted) Navigator.pop(context);

    if (!result.canReorder) {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Cannot reorder'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check for price changes
    if (result.hasPriceChanges) {
      if (context.mounted) {
        final proceed = await _showPriceChangesDialog(
          context,
          result.priceChanges,
        );
        if (!proceed) return;
      }
    }

    // Add to cart
    onAddToCart(result.cartItems);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items added to cart!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<bool> _showPriceChangesDialog(
    BuildContext context,
    List<PriceChange> changes,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text('Price Changes'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Some items have changed in price:'),
                const SizedBox(height: 12),
                ...changes
                    .where((c) => c.newPrice != c.oldPrice)
                    .map(
                      (change) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(change.itemName)),
                            Text(
                              '${change.oldPrice.toStringAsFixed(0)} → ${change.newPrice.toStringAsFixed(0)} SYP',
                              style: TextStyle(
                                color: change.newPrice > change.oldPrice
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Proceed with new prices'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// =====================================================
// ORDER MODEL (Updated)
// =====================================================

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String restaurantId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });
}

class OrderItem {
  final String? productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final dynamic selectedModifiers;
  final String? customRequest;

  OrderItem({
    this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.selectedModifiers,
    this.customRequest,
  });
}

class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final List<SelectedModifier> modifiers;
  final String? customRequest;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.modifiers = const [],
    this.customRequest,
  });
}

class SelectedModifier {
  final String groupName;
  final String optionName;
  final double price;

  SelectedModifier({
    required this.groupName,
    required this.optionName,
    required this.price,
  });
}
