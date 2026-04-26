class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String category;
  final String? subCategory;
  final String? brand;
  final List<String>? imageUrls;
  final Map<String, dynamic>? specifications;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    required this.category,
    this.subCategory,
    this.brand,
    this.imageUrls,
    this.specifications,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      stockQuantity: json['stock_quantity'] ?? 0,
      category: json['category'] ?? '',
      subCategory: json['sub_category'],
      brand: json['brand'],
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : null,
      specifications: json['specifications'] is Map ? Map<String, dynamic>.from(json['specifications']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  String get mainImageUrl => imageUrls?.isNotEmpty == true ? imageUrls!.first : 'https://via.placeholder.com/300x300?text=No+Image';

  bool get inStock => stockQuantity > 0;

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
    };
  }
}