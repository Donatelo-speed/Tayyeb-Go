import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartItem {
  final int productId;
  final String name;
  final double price;
  int quantity;
  Product? product;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.product,
  });

  double get total => price * quantity;
  String get displayName => name.isNotEmpty ? name : (product?.displayName ?? 'Unknown');
}

class CartProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  Map<int, CartItem> _items = {};
  bool _isLoading = false;
  String? _error;

  Map<int, CartItem> get items => Map.from(_items);
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.total);
  double get deliveryFee => subtotal > 50 ? 0 : 5;
  double get total => subtotal + deliveryFee;
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isInCart(int productId) => _items.containsKey(productId);

  Future<void> loadCart() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final data = await _api.getCart();
      final items = (data['items'] as List?) ?? [];
      
      _items = {};
      for (final item in items) {
        final product = item['product'];
        final cartItem = CartItem(
          productId: item['productId'],
          name: product?['name'] ?? 'Product',
          price: (item['price'] ?? 0).toDouble(),
          quantity: item['quantity'] ?? 1,
          product: product != null ? Product.fromJson(product) : null,
        );
        _items[item['productId']] = cartItem;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(
        productId: product.id,
        name: product.displayName,
        price: product.price,
        quantity: quantity,
        product: product,
      );
    }
    notifyListeners();
    
    try {
      await _api.addToCart(product.id, quantity: quantity);
    } catch (e) {
      // Keep local cart even if API fails
    }
  }

  Future<void> removeFromCart(int productId) async {
    _items.remove(productId);
    notifyListeners();
    
    try {
      await _api.removeFromCart(productId);
    } catch (e) {
      // Keep local cart even if API fails
    }
  }

  void updateQuantity(int productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        removeFromCart(productId);
      } else {
        _items[productId]!.quantity = quantity;
        notifyListeners();
      }
    }
  }

  void increment(int productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      notifyListeners();
    }
  }

  void decrement(int productId) {
    if (_items.containsKey(productId) && _items[productId]!.quantity > 1) {
      _items[productId]!.quantity--;
      notifyListeners();
    } else {
      removeFromCart(productId);
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    
    try {
      await _api.clearCart();
    } catch (e) {
      // Keep local cart even if API fails
    }
  }

  Future<bool> checkout(String address, String phone, {String? notes}) async {
    try {
      final items = _items.values.map((item) => {
        'productId': item.productId,
        'quantity': item.quantity,
        'price': item.price,
      }).toList();
      
      await _api.createOrder(items, address, phone, notes: notes);
      await clearCart();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}