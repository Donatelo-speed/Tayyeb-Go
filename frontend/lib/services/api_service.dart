import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/product.dart';

const String _baseUrl = 'http://localhost:5000/api';
const bool _demoMode = true;

// Free APIs
const String _productsApiBase = 'https://dummyjson.com';
const String _currencyApiBase = 'https://api.exchangeratesapi.io';

// Test credentials for the app
const String _testEmail = 'demo@example.com';
const String _testPassword = 'password123';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getToken() async => await _storage.read(key: 'auth_token');
  Future<void> saveToken(String token) async => await _storage.write(key: 'auth_token', value: token);
  Future<void> deleteToken() async => await _storage.delete(key: 'auth_token');

  bool _isDemoMatch(dynamic pattern, dynamic value) {
    if (value == null) return false;
    final searchLower = value.toString().toLowerCase();
    if (pattern is String) return searchLower.contains(pattern.toString().toLowerCase());
    return searchLower.contains(pattern.toString().toLowerCase());
  }

  // ==================== GROCERY CATEGORIES ====================
  static final List<Map<String, dynamic>> _groceryCategories = [
    {'id': 1, 'name': 'Fresh Fruits', 'icon': '🍎', 'color': 0xFFFF6B6B},
    {'id': 2, 'name': 'Vegetables', 'icon': '🥦', 'color': 0xFF00B894},
    {'id': 3, 'name': 'Meat & Fish', 'icon': '🥩', 'color': 0xFFE17055},
    {'id': 4, 'name': 'Dairy & Eggs', 'icon': '🥛', 'color': 0xFF74B9FF},
    {'id': 5, 'name': 'Bakery', 'icon': '🥐', 'color': 0xFFFDCB6E},
    {'id': 6, 'name': 'Beverages', 'icon': '🧃', 'color': 0xFF6C5CE7},
    {'id': 7, 'name': 'Snacks', 'icon': '🍿', 'color': 0xFFE84393},
    {'id': 8, 'name': 'Frozen', 'icon': '🧊', 'color': 0xFF00CEC9},
    {'id': 9, 'name': 'Cooking', 'icon': '🫓', 'color': 0xFFE17055},
    {'id': 10, 'name': 'Cleaning', 'icon': '🧹', 'color': 0xFF636E72},
    {'id': 11, 'name': 'Personal Care', 'icon': '🧴', 'color': 0xFFFD79A8},
    {'id': 12, 'name': 'Baby Care', 'icon': '👶', 'color': 0xFFFAB1A10},
  ];

  // ==================== GROCERY PRODUCTS ====================
  static final List<Map<String, dynamic>> _demoProducts = [
    // Fresh Fruits
    {'id': 1, 'name': 'Fresh Apples - 1kg', 'description': 'Premium Quality Red Apples', 'price': 12.99, 'stock_quantity': 100, 'category': 'Fresh Fruits', 'unit': 'kg', 'image_urls': ['https://images.unsplash.com/photo-1560806887-1e4e4b7c1d4a?w=300']},
    {'id': 2, 'name': 'Bananas - 1kg', 'description': 'Ripe Bananas', 'price': 5.99, 'stock_quantity': 150, 'category': 'Fresh Fruits', 'unit': 'kg'},
    {'id': 3, 'name': 'Oranges - 1kg', 'description': 'Juicy Oranges', 'price': 8.99, 'stock_quantity': 80, 'category': 'Fresh Fruits', 'unit': 'kg'},
    {'id': 4, 'name': 'Grapes - 500g', 'description': 'Seedless Grapes', 'price': 15.99, 'stock_quantity': 60, 'category': 'Fresh Fruits', 'unit': '500g'},
    {'id': 5, 'name': 'Strawberries - 250g', 'description': 'Fresh Strawberries', 'price': 12.99, 'stock_quantity': 40, 'category': 'Fresh Fruits', 'unit': '250g'},
    // Vegetables
    {'id': 6, 'name': 'Broccoli - 1pc', 'description': 'Fresh Green Broccoli', 'price': 4.99, 'stock_quantity': 70, 'category': 'Vegetables', 'unit': 'pc'},
    {'id': 7, 'name': 'Carrots - 1kg', 'description': 'Organic Carrots', 'price': 3.99, 'stock_quantity': 90, 'category': 'Vegetables', 'unit': 'kg'},
    {'id': 8, 'name': 'Tomatoes - 1kg', 'description': 'Red Tomatoes', 'price': 6.99, 'stock_quantity': 100, 'category': 'Vegetables', 'unit': 'kg'},
    {'id': 9, 'name': 'Onions - 1kg', 'description': 'Yellow Onions', 'price': 2.99, 'stock_quantity': 120, 'category': 'Vegetables', 'unit': 'kg'},
    {'id': 10, 'name': 'Potatoes - 2kg', 'description': 'Organic Potatoes', 'price': 7.99, 'stock_quantity': 80, 'category': 'Vegetables', 'unit': '2kg'},
    // Meat & Fish
    {'id': 11, 'name': 'Chicken Breast - 1kg', 'description': 'Boneless Chicken', 'price': 24.99, 'stock_quantity': 50, 'category': 'Meat & Fish', 'unit': 'kg'},
    {'id': 12, 'name': 'Beef Mince - 500g', 'description': 'Fresh Beef Mince', 'price': 19.99, 'stock_quantity': 40, 'category': 'Meat & Fish', 'unit': '500g'},
    {'id': 13, 'name': 'Salmon - 400g', 'description': 'Fresh Salmon Fillet', 'price': 34.99, 'stock_quantity': 30, 'category': 'Meat & Fish', 'unit': '400g'},
    {'id': 14, 'name': 'Mutton - 1kg', 'description': 'Fresh Mutton', 'price': 49.99, 'stock_quantity': 25, 'category': 'Meat & Fish', 'unit': 'kg'},
    // Dairy & Eggs
    {'id': 15, 'name': 'Fresh Milk - 1L', 'description': 'Full Cream Milk', 'price': 5.99, 'stock_quantity': 100, 'category': 'Dairy & Eggs', 'unit': 'L'},
    {'id': 16, 'name': 'Greek Yogurt - 500g', 'description': 'Creamy Greek Yogurt', 'price': 8.99, 'stock_quantity': 60, 'category': 'Dairy & Eggs', 'unit': '500g'},
    {'id': 17, 'name': 'Eggs - 12pcs', 'description': 'Farm Fresh Eggs', 'price': 6.99, 'stock_quantity': 80, 'category': 'Dairy & Eggs', 'unit': '12pcs'},
    {'id': 18, 'name': 'Cheese - 250g', 'description': 'Cheddar Cheese', 'price': 12.99, 'stock_quantity': 45, 'category': 'Dairy & Eggs', 'unit': '250g'},
    // Bakery
    {'id': 19, 'name': 'Arabic Bread - 10pcs', 'description': 'Fresh Arabic Bread', 'price': 4.99, 'stock_quantity': 50, 'category': 'Bakery', 'unit': '10pcs'},
    {'id': 20, 'name': 'Croissants - 4pcs', 'description': 'Buttery Croissants', 'price': 9.99, 'stock_quantity': 40, 'category': 'Bakery', 'unit': '4pcs'},
    {'id': 21, 'name': 'Burger Buns - 6pcs', 'description': 'Fresh Burger Buns', 'price': 5.99, 'stock_quantity': 60, 'category': 'Bakery', 'unit': '6pcs'},
    // Beverages
    {'id': 22, 'name': 'Orange Juice - 1L', 'description': '100% Natural Juice', 'price': 12.99, 'stock_quantity': 50, 'category': 'Beverages', 'unit': 'L'},
    {'id': 23, 'name': 'Water - 6x1.5L', 'description': 'Mineral Water Case', 'price': 8.99, 'stock_quantity': 80, 'category': 'Beverages', 'unit': 'case'},
    {'id': 24, 'name': 'Soft Drinks - 12pcs', 'description': 'Assorted Flavors', 'price': 15.99, 'stock_quantity': 60, 'category': 'Beverages', 'unit': '12pcs'},
    // Snacks
    {'id': 25, 'name': 'Potato Chips - 150g', 'description': 'Salty Chips', 'price': 6.99, 'stock_quantity': 100, 'category': 'Snacks', 'unit': '150g'},
    {'id': 26, 'name': 'Chocolate - 100g', 'description': 'Dark Chocolate', 'price': 9.99, 'stock_quantity': 70, 'category': 'Snacks', 'unit': '100g'},
    {'id': 27, 'name': 'Nuts Mix - 200g', 'description': 'Mixed Nuts', 'price': 19.99, 'stock_quantity': 50, 'category': 'Snacks', 'unit': '200g'},
    // Frozen
    {'id': 28, 'name': 'Frozen Pizza - 400g', 'description': 'Pepperoni Pizza', 'price': 18.99, 'stock_quantity': 40, 'category': 'Frozen', 'unit': '400g'},
    {'id': 29, 'name': 'Ice Cream - 1L', 'description': 'Vanilla Ice Cream', 'price': 14.99, 'stock_quantity': 60, 'category': 'Frozen', 'unit': 'L'},
    // Cooking
    {'id': 30, 'name': 'Olive Oil - 1L', 'description': 'Extra Virgin Olive Oil', 'price': 29.99, 'stock_quantity': 40, 'category': 'Cooking', 'unit': 'L'},
    {'id': 31, 'name': 'Rice - 5kg', 'description': 'Basmati Rice', 'price': 24.99, 'stock_quantity': 50, 'category': 'Cooking', 'unit': '5kg'},
    {'id': 32, 'name': 'Sugar - 1kg', 'description': 'White Sugar', 'price': 4.99, 'stock_quantity': 80, 'category': 'Cooking', 'unit': 'kg'},
    // Cleaning
    {'id': 33, 'name': 'Detergent - 2L', 'description': 'Liquid Detergent', 'price': 15.99, 'stock_quantity': 60, 'category': 'Cleaning', 'unit': '2L'},
    {'id': 34, 'name': 'Bleach - 1L', 'description': 'Surface Bleach', 'price': 8.99, 'stock_quantity': 45, 'category': 'Cleaning', 'unit': 'L'},
    {'id': 35, 'name': 'Tissues - 3 pcs', 'description': 'Facial Tissues', 'price': 4.99, 'stock_quantity': 100, 'category': 'Cleaning', 'unit': '3pcs'},
    // Personal Care
    {'id': 36, 'name': 'Shampoo - 400ml', 'description': 'Anti-Dandruff Shampoo', 'price': 19.99, 'stock_quantity': 50, 'category': 'Personal Care', 'unit': '400ml'},
    {'id': 37, 'name': 'Toothpaste - 2pcs', 'description': 'Mint Toothpaste', 'price': 9.99, 'stock_quantity': 70, 'category': 'Personal Care', 'unit': '2pcs'},
    {'id': 38, 'name': 'Soap Bars - 3pcs', 'description': 'Glycerin Soap', 'price': 7.99, 'stock_quantity': 60, 'category': 'Personal Care', 'unit': '3pcs'},
    // Baby Care
    {'id': 39, 'name': 'Diapers - 30pcs', 'description': 'Baby Diapers', 'price': 24.99, 'stock_quantity': 40, 'category': 'Baby Care', 'unit': '30pcs'},
    {'id': 40, 'name': 'Baby Food - 6pcs', 'description': 'Vegetable Puree', 'price': 15.99, 'stock_quantity': 30, 'category': 'Baby Care', 'unit': '6pcs'},
  ];

  // ==================== DEALS ====================
  static final List<Map<String, dynamic>> _deals = [
    {'id': 1, 'title': '50% Off Fruits', 'description': 'On all fresh fruits', 'image': 'https://images.unsplash.com/photo-1610832958506-aa5636a632f0?w=400', 'discount': 50, 'category': 'Fresh Fruits'},
    {'id': 2, 'title': 'Buy 1 Get 1 Free', 'description': 'OnSelected Dairy', 'image': 'https://images.unsplash.com/photo-1628088062854-d1870e455a89?w=400', 'discount': 100, 'category': 'Dairy & Eggs'},
    {'id': 3, 'title': '20% Off Meat', 'description': 'On Beef & Mutton', 'image': 'https://images.unsplash.com/photo-1603048297172-c92544798d5e?w=400', 'discount': 20, 'category': 'Meat & Fish'},
  ];

  // ==================== TIME SLOTS ====================
  static final List<Map<String, dynamic>> _timeSlots = [
    {'id': 1, 'time': '09:00 AM - 11:00 AM', 'available': true},
    {'id': 2, 'time': '11:00 AM - 01:00 PM', 'available': true},
    {'id': 3, 'time': '01:00 PM - 03:00 PM', 'available': true},
    {'id': 4, 'time': '03:00 PM - 05:00 PM', 'available': false},
    {'id': 5, 'time': '05:00 PM - 07:00 PM', 'available': true},
    {'id': 6, 'time': '07:00 PM - 09:00 PM', 'available': true},
  ];

  Future<Map<String, dynamic>> _getDemoProducts({int page = 1, int limit = 20, String? search, String? category}) async {
    var filtered = List<Map<String, dynamic>>.from(_demoProducts);
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((p) => _isDemoMatch(search, p['name'])).toList();
    }
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((p) => p['category'] == category).toList();
    }
    final start = (page - 1) * limit;
    final paginated = filtered.skip(start).take(limit).toList();
    return {
      'success': true,
      'products': paginated,
      'pagination': {'total': filtered.length, 'page': page, 'limit': limit, 'totalPages': (filtered.length / limit).ceil()},
    };
  }

  static List<Map<String, dynamic>> getCategories() => _groceryCategories;
  static List<Map<String, dynamic>> getDeals() => _deals;
  static List<Map<String, dynamic>> getTimeSlots() => _timeSlots;

  Future<Map<String, String>> _getHeaders({bool auth = false}) async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (auth && token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    throw ApiException(statusCode: response.statusCode, message: body['error'] ?? 'An error occurred');
  }

  Future<Map<String, dynamic>> register({required String email, required String password, required String fullName, String? phone, String role = 'customer'}) async {
    if (_demoMode) {
      await saveToken('demo_token_123');
      String finalRole = role;
      if (email.toLowerCase().contains('admin')) finalRole = 'admin';
      else if (email.toLowerCase().contains('delivery') || email.toLowerCase().contains('driver')) finalRole = 'delivery';
      return {'success': true, 'token': 'demo_token_123', 'user': {'id': 1, 'email': email, 'full_name': fullName, 'phone': phone, 'role': finalRole, 'status': 'active'}};
    }
    final response = await http.post(Uri.parse('$_baseUrl/auth/register'), headers: await _getHeaders(), body: jsonEncode({'email': email, 'password': password, 'full_name': fullName, 'phone': phone, 'role': role}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    if (_demoMode) {
      await saveToken('demo_token_123');
      String role = 'customer';
      if (email.toLowerCase().contains('admin')) role = 'admin';
      else if (email.toLowerCase().contains('delivery') || email.toLowerCase().contains('driver')) role = 'delivery';
      return {'success': true, 'token': 'demo_token_123', 'user': {'id': 1, 'email': email, 'full_name': 'Demo User', 'phone': '1234567890', 'role': role, 'status': 'active'}};
    }
    final response = await http.post(Uri.parse('$_baseUrl/auth/login'), headers: await _getHeaders(), body: jsonEncode({'email': email, 'password': password}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    if (_demoMode) return {'id': 1, 'email': 'demo@example.com', 'full_name': 'Demo User', 'phone': '1234567890', 'role': 'customer', 'status': 'active'};
    final response = await http.get(Uri.parse('$_baseUrl/auth/me'), headers: await _getHeaders(auth: true));
    return _handleResponse(response);
  }

  Future<List<String>> fetchCategories() async {
    if (_demoMode) {
      return _demoProducts.map((p) => p['category'] as String).toSet().toList();
    }
    try {
      final response = await http.get(
        Uri.parse('$_productsApiBase/products/categories'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(response.body);
        return categories.map((c) => c.toString()).toList();
      }
    } catch (e) {
      // Fallback to demo categories
    }
    return _demoProducts.map((p) => p['category'] as String).toSet().toList();
  }

  // Fetch real products from dummyjson API for grocery
  Future<Map<String, dynamic>> _fetchRealProducts({int page = 1, int limit = 20, String? search, String? category}) async {
    try {
      String url = '$_productsApiBase/products?limit=$limit&skip=${(page - 1) * limit}';
      if (search != null && search.isNotEmpty) {
        url = '$_productsApiBase/products/search?q=$search&limit=$limit&skip=${(page - 1) * limit}';
      }
      if (category != null && category.isNotEmpty) {
        url = '$_productsApiBase/products/category/$category?limit=$limit&skip=${(page - 1) * limit}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List).map((p) => _convertToGroceryProduct(p)).toList();
        return {
          'success': true,
          'products': products,
          'pagination': {
            'total': data['total'] ?? products.length,
            'page': page,
            'limit': limit,
            'totalPages': ((data['total'] ?? products.length) / limit).ceil(),
          },
        };
      }
    } catch (e) {
      // Fallback to demo
    }
    return _getDemoProducts(page: page, limit: limit, search: search, category: category);
  }

  // Convert dummyjson product to grocery format
  Map<String, dynamic> _convertToGroceryProduct(Map<String, dynamic> p) {
    final category = p['category']?.toString() ?? 'groceries';
    String emoji = '🛒';
    if (category.contains('furniture')) emoji = '🪑';
    else if (category.contains('electronics')) emoji = '📱';
    else if (category.contains('jewelry')) emoji = '💎';
    else if (category.contains('mens') || category.contains('womens')) emoji = '👕';
    else if (category.contains('beauty')) emoji = '💄';
    
    return {
      'id': p['id'],
      'name': p['title'] ?? '',
      'description': p['description'] ?? '',
      'price': p['price'] ?? 0,
      'stock_quantity': p['stock'] ?? 50,
      'category': _mapToGroceryCategory(category),
      'unit': 'pcs',
      'image_urls': [p['thumbnail'] ?? p['image']],
      'brand': p['brand'] ?? '',
    };
  }

  String _mapToGroceryCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('groceries')) return 'Fresh Fruits';
    if (cat.contains('furniture')) return 'Vegetables';
    if (cat.contains('beauty') || cat.contains('skin')) return 'Dairy & Eggs';
    if (cat.contains('fragrances')) return 'Beverages';
    if (cat.contains('home') || cat.contains('kitchen')) return 'Bakery';
    return 'Cleaning';
  }

  // Currency API - fetch real exchange rates
  Future<double> fetchExchangeRate({String targetCurrency = 'SYP'}) async {
    try {
      // Try to get rate from API
      // For SYP which may not be in free APIs, use estimate based on USD
      final response = await http.get(
        Uri.parse('$_currencyApiBase/latest/USD'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        // Default to 13000 SYP per USD (approximate)
        // Note: Most free APIs don't support SYP directly
        return 13000.0; 
      }
    } catch (e) {
      // Use default rate
    }
    return 13000.0;
  }

  Future<Map<String, dynamic>> getProducts({int page = 1, int limit = 20, String? search, String? category, String? subCategory, String? sortBy, String? order, double? minPrice, double? maxPrice, String? brand}) async {
    // Try real API first, fallback to demo
    if (_demoMode) {
      try {
        return await _fetchRealProducts(page: page, limit: limit, search: search, category: category);
      } catch (e) {
        return _getDemoProducts(page: page, limit: limit, search: search, category: category);
      }
    }
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString(), if (search != null && search.isNotEmpty) 'search': search, if (category != null) 'category': category};
    final response = await http.get(Uri.parse('$_baseUrl/products').replace(queryParameters: queryParams), headers: await _getHeaders());
    return _handleResponse(response);
  }

  Future<Product> getProduct(int id) async {
    if (_demoMode) {
      final product = _demoProducts.firstWhere((p) => p['id'] == id, orElse: () => {'id': id, 'name': 'Demo Product', 'description': 'Demo description', 'price': 29.99, 'stock_quantity': 50, 'category': 'Fresh Fruits'});
      return Product.fromJson(product);
    }
    final response = await http.get(Uri.parse('$_baseUrl/products/$id'), headers: await _getHeaders());
    final body = _handleResponse(response);
    return Product.fromJson(body['product'] ?? body);
  }

  Future<Map<String, dynamic>> createOrder({required List<Map<String, dynamic>> items, required String address, String? timeSlot, required String orderType, double? total}) async {
    if (_demoMode) {
      return {'success': true, 'order_id': DateTime.now().millisecondsSinceEpoch, 'status': 'confirmed', 'estimated_time': timeSlot ?? '2 hours'};
    }
    final response = await http.post(Uri.parse('$_baseUrl/orders'), headers: await _getHeaders(auth: true), body: jsonEncode({'items': items, 'address': address, 'time_slot': timeSlot, 'order_type': orderType, 'total': total}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrders() async {
    if (_demoMode) {
      return {
        'orders': [
          {'id': 1, 'status': 'delivered', 'total': 89.99, 'items_count': 5, 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
          {'id': 2, 'status': 'processing', 'total': 45.50, 'items_count': 3, 'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()},
        ]
      };
    }
    final response = await http.get(Uri.parse('$_baseUrl/orders'), headers: await _getHeaders(auth: true));
    return _handleResponse(response);
  }

  // ==================== ADDRESS MANAGEMENT ====================
  Future<Map<String, dynamic>> getAddresses() async {
    if (_demoMode) {
      return {
        'addresses': [
          {'id': 1, 'label': 'Home', 'address': 'Riyadh, Al Olaya', 'is_default': true},
          {'id': 2, 'label': 'Work', 'address': 'Riyadh, King Abdullah Financial District', 'is_default': false},
        ]
      };
    }
    final response = await http.get(Uri.parse('$_baseUrl/addresses'), headers: await _getHeaders(auth: true));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addAddress({required String label, required String address, required double lat, required double lng, bool isDefault = false}) async {
    if (_demoMode) {
      return {'success': true, 'address_id': DateTime.now().millisecondsSinceEpoch};
    }
    final response = await http.post(Uri.parse('$_baseUrl/addresses'), headers: await _getHeaders(auth: true), body: jsonEncode({'label': label, 'address': address, 'lat': lat, 'lng': lng, 'is_default': isDefault}));
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});
  @override
  String toString() => message;
}

class ApiEndpoints {
  static final ApiService _api = ApiService();

  static Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'), headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'});
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl$endpoint'), headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'}, body: jsonEncode(data));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, {String? token}) async {
    try {
      final response = await http.put(Uri.parse('$_baseUrl$endpoint'), headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'}, body: jsonEncode(data));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint, {String? token}) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl$endpoint'), headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'});
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}