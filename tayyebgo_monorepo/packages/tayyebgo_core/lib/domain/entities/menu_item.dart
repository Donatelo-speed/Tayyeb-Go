import '../value_objects/money.dart';
import 'menu_modifier.dart';

class MenuItem {
  final String id;
  final String brandId;
  final String? branchId;
  final String? sharedItemId;
  final String name;
  final String description;
  final Money price;
  final Money? originalPrice;
  final String category;
  final List<String> tags;
  final List<MenuModifierGroup> modifierGroups;
  final bool isAvailable;
  final bool isSignature;
  final String? imageUrl;
  final int sortOrder;
  final DateTime createdAt;

  const MenuItem({
    required this.id,
    required this.brandId,
    this.branchId,
    this.sharedItemId,
    required this.name,
    this.description = '',
    required this.price,
    this.originalPrice,
    this.category = 'Main Course',
    this.tags = const [],
    this.modifierGroups = const [],
    this.isAvailable = true,
    this.isSignature = false,
    this.imageUrl,
    this.sortOrder = 0,
    required this.createdAt,
  });

  bool get isSharedItem => branchId == null;
  bool get isBranchOverride => branchId != null;
  bool get hasDiscount => originalPrice != null && originalPrice!.amountInCents > price.amountInCents;
  Money get effectivePrice => originalPrice ?? price;
  int get discountPercent => hasDiscount ? ((originalPrice!.amountInCents - price.amountInCents) * 100 ~/ originalPrice!.amountInCents) : 0;

  MenuItem copyWith({
    String? name,
    String? description,
    Money? price,
    Money? originalPrice,
    String? category,
    List<String>? tags,
    List<MenuModifierGroup>? modifierGroups,
    bool? isAvailable,
    bool? isSignature,
    String? imageUrl,
    int? sortOrder,
    String? branchId,
  }) =>
      MenuItem(
        id: id,
        brandId: brandId,
        branchId: branchId ?? this.branchId,
        sharedItemId: sharedItemId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        originalPrice: originalPrice ?? this.originalPrice,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        modifierGroups: modifierGroups ?? this.modifierGroups,
        isAvailable: isAvailable ?? this.isAvailable,
        isSignature: isSignature ?? this.isSignature,
        imageUrl: imageUrl ?? this.imageUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'brandId': brandId,
        if (branchId != null) 'branchId': branchId,
        if (sharedItemId != null) 'sharedItemId': sharedItemId,
        'name': name,
        'description': description,
        'price': price.amountInCents,
        if (originalPrice != null) 'originalPrice': originalPrice!.amountInCents,
        'category': category,
        'tags': tags,
        'modifierGroups': modifierGroups.map((m) => m.toMap()).toList(),
        'isAvailable': isAvailable,
        'isSignature': isSignature,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MenuItem.fromMap(Map<String, dynamic> m, String docId) => MenuItem(
        id: docId,
        brandId: m['brandId'] as String? ?? '',
        branchId: m['branchId'] as String?,
        sharedItemId: m['sharedItemId'] as String?,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        price: Money((m['price'] as num?)?.toInt() ?? 0),
        originalPrice: m['originalPrice'] != null
            ? Money((m['originalPrice'] as num).toInt())
            : null,
        category: m['category'] as String? ?? 'Main Course',
        tags: (m['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        modifierGroups: (m['modifierGroups'] as List<dynamic>?)
                ?.map((e) =>
                    MenuModifierGroup.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        isAvailable: m['isAvailable'] as bool? ?? true,
        isSignature: m['isSignature'] as bool? ?? false,
        imageUrl: m['imageUrl'] as String?,
        sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}