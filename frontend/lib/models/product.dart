import 'modifier.dart';

class Product {
  final int id;
  final String? name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? category;
  final String? subCategory;
  final String? brand;
  final List<String>? imageUrls;
  final Map<String, dynamic>? specifications;
  final DateTime? createdAt;
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;
  final int preparationTime;

  // ─── Modifier system ───────────────────────────────────────────────────────
  /// Ordered list of modifier groups the customer configures before adding
  /// this product to their cart (e.g. "Protein", "Extras", "Remove Items").
  final List<ModifierGroup>? modifierGroups;

  /// Frequently paired / upsell products shown on the product detail sheet.
  final List<UpsellLink>? upsellLinks;

  Product({
    required this.id,
    this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.category,
    this.subCategory,
    this.brand,
    this.imageUrls,
    this.specifications,
    this.createdAt,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isSpicy = false,
    this.preparationTime = 15,
    this.modifierGroups,
    this.upsellLinks,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      stockQuantity: json['stock_quantity'] ?? 0,
      category: json['category']?.toString(),
      subCategory: json['sub_category']?.toString(),
      brand: json['brand']?.toString(),
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isVegetarian: json['is_vegetarian'] ?? false,
      isVegan: json['is_vegan'] ?? false,
      isSpicy: json['is_spicy'] ?? false,
      preparationTime: json['preparation_time'] ?? 15,
      modifierGroups: json['modifier_groups'] != null
          ? (json['modifier_groups'] as List)
              .map((g) => ModifierGroup.fromJson(g as Map<String, dynamic>))
              .toList()
          : null,
      upsellLinks: json['upsell_links'] != null
          ? (json['upsell_links'] as List)
              .map((u) => UpsellLink.fromJson(u as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'category': category,
      'sub_category': subCategory,
      'brand': brand,
      'image_urls': imageUrls,
      'specifications': specifications,
      'created_at': createdAt?.toIso8601String(),
      'is_vegetarian': isVegetarian,
      'is_vegan': isVegan,
      'is_spicy': isSpicy,
      'preparation_time': preparationTime,
      'modifier_groups':
          modifierGroups?.map((g) => g.toJson()).toList(),
      'upsell_links': upsellLinks?.map((u) => u.toJson()).toList(),
    };
  }

  /// Whether this product requires the modifier sheet before add-to-cart.
  bool get hasModifiers =>
      modifierGroups != null && modifierGroups!.isNotEmpty;

  /// Whether ANY modifier group is required (the sheet must be shown).
  bool get hasRequiredModifiers =>
      modifierGroups?.any((g) => g.isRequired) ?? false;

  String get mainImageUrl => imageUrls?.isNotEmpty == true
      ? imageUrls!.first
      : 'https://via.placeholder.com/300x300?text=No+Image';

  String get displayName => name ?? 'Unknown Product';
  String get displayCategory => category ?? 'Uncategorized';
  bool get inStock => stockQuantity > 0;

  double get safeDiscount => 0.0;
  double get safeOriginalPrice => price;
  String get safeName => displayName;
  String get safeCategory => displayCategory;
}
