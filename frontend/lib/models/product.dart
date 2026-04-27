class Product {
  // Added a placeholder 'unit' property for compatibility with older screens
  String get unit => '';

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
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : null,
      specifications: json['specifications'] is Map ? Map<String, dynamic>.from(json['specifications']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  String get mainImageUrl => imageUrls?.isNotEmpty == true ? imageUrls!.first : 'https://via.placeholder.com/300x300?text=No+Image';
  String get displayName => name ?? 'Unknown Product';
  String get displayCategory => category ?? 'Uncategorized';
  bool get inStock => stockQuantity > 0;
  
  // Safe getters with fallback values
  double get safeDiscount => 0.0;
  double get safeOriginalPrice => price;
  
  // Safe getters for direct property access
  String get safeName => displayName;
  String get safeCategory => displayCategory;

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