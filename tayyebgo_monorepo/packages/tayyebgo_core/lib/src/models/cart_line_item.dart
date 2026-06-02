import 'product.dart';
import 'modifier.dart';

class CartLineItem {
  final String lineId;
  final Product product;
  final int quantity;
  final List<SelectedModifierGroup> selectedModifiers;
  final String? customerNote;

  CartLineItem({
    required this.lineId,
    required this.product,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.customerNote,
  });

  double get modifiersTotal {
    double total = 0;
    for (final group in selectedModifiers) {
      for (final optionId in group.selectedOptionIds) {
        final option = group.group.options
            .where((o) => o.id == optionId)
            .firstOrNull;
        if (option != null) {
          total += option.priceAdjustment;
        }
      }
    }
    return total;
  }

  double get unitPrice => product.price + modifiersTotal;
  double get lineTotal => unitPrice * quantity;

  bool hasSameConfigAs(Product other, List<SelectedModifierGroup> mods) {
    if (product.id != other.id) return false;
    if (selectedModifiers.length != mods.length) return false;
    for (int i = 0; i < selectedModifiers.length; i++) {
      if (selectedModifiers[i].groupId != mods[i].groupId) return false;
      if (selectedModifiers[i].selectedOptionIds.join(',') !=
          mods[i].selectedOptionIds.join(',')) {
        return false;
      }
    }
    return true;
  }

  CartLineItem copyWith({
    String? lineId,
    Product? product,
    int? quantity,
    List<SelectedModifierGroup>? selectedModifiers,
    String? customerNote,
  }) {
    return CartLineItem(
      lineId: lineId ?? this.lineId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      customerNote: customerNote ?? this.customerNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'product': {
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'firestore_id': product.firestoreId,
          'image_url': product.imageUrl,
          'category': product.category,
          'restaurant_id': product.restaurantId,
          'is_available': product.isAvailable,
          'sort_order': product.sortOrder,
          'compare_price': product.comparePrice,
          'description': product.description,
        },
        'quantity': quantity,
        'selected_modifiers': selectedModifiers.map((m) => m.toJson()).toList(),
        if (customerNote != null) 'customer_note': customerNote,
        'line_total': lineTotal,
      };

  factory CartLineItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] as Map<String, dynamic>? ?? {};
    final product = Product(
      id: (productData['id'] as num?)?.toInt() ?? 0,
      firestoreId: productData['firestore_id']?.toString() ?? '',
      name: productData['name'] as String? ?? '',
      price: (productData['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: productData['image_url'] as String?,
      category: productData['category'] as String? ?? '',
      restaurantId: productData['restaurant_id']?.toString(),
      isAvailable: productData['is_available'] as bool? ?? true,
      sortOrder: (productData['sort_order'] as num?)?.toInt() ?? 0,
      comparePrice: (productData['compare_price'] as num?)?.toDouble(),
      description: productData['description'] as String?,
    );
    final modifiers = (json['selected_modifiers'] as List<dynamic>?)
            ?.map((e) => SelectedModifierGroup.fromJson(
                  e as Map<String, dynamic>,
                  ModifierGroup(id: '', name: ''),
                ))
            .toList() ??
        [];
    return CartLineItem(
      lineId: json['line_id'] as String? ?? '',
      product: product,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedModifiers: modifiers,
      customerNote: json['customer_note'] as String?,
    );
  }
}
