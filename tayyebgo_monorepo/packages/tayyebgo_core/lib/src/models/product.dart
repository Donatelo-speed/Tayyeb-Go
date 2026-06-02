import 'modifier.dart';

class ProductCategory {
  final String id;
  final String name;
  final String? nameAr;
  final String? imageUrl;
  final int sortOrder;

  ProductCategory({
    required this.id,
    required this.name,
    this.nameAr,
    this.imageUrl,
    this.sortOrder = 0,
  });
}

class Product {
  final int id;
  final String firestoreId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final double price;
  final double? comparePrice;
  final String? imageUrl;
  final String category;
  final String? categoryId;
  final String? restaurantId;
  final bool isAvailable;
  final int sortOrder;
  final List<ModifierGroup>? modifierGroups;
  final double? rating;
  final int? reviewCount;
  final DateTime? createdAt;

  Product({
    required this.id,
    this.firestoreId = '',
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    required this.price,
    this.comparePrice,
    this.imageUrl,
    this.category = '',
    this.categoryId,
    this.restaurantId,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.modifierGroups,
    this.rating,
    this.reviewCount,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firestoreId: json['firestoreId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      comparePrice: (json['compare_price'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      category: json['category'] as String? ?? '',
      categoryId: json['category_id']?.toString(),
      restaurantId: json['restaurant_id']?.toString() ?? json['restaurantId'] as String?,
      isAvailable: json['is_available'] as bool? ?? json['isAvailable'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? json['sortOrder'] as int? ?? 0,
      modifierGroups: json['modifier_groups'] != null
          ? (json['modifier_groups'] as List)
              .map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
              .toList()
          : (json['modifierGroups'] as List?)
              ?.map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
              .toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? json['reviewCount'] as int?,
    );
  }
}
