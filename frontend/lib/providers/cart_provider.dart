import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/product.dart';

class CartItem {
  final int productId;
  final String name;
  final double price;
  final double priceUSD;
  int quantity;
  CartItem({required this.productId, required this.name, required this.price, double? priceUSD, this.quantity = 1}) : priceUSD = priceUSD ?? price;
  double get totalPrice => price * quantity;
}

class CartProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<int, CartItem> _items = {};
  String? _currentUserId;
  bool _isGuestCart = false;

  Map<int, CartItem> get items => Map.unmodifiable(_items);
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.values.fold(0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _items.isEmpty;
  bool get isGuestCart => _isGuestCart && _currentUserId == null;
  bool get hasItems => _items.isNotEmpty;

  bool isInCart(int productId) => _items.containsKey(productId);

  // Ghost Cart - Add without login
  void addToCartGuest(Product product, {int quantity = 1}) {
    _isGuestCart = true;
    _currentUserId = null;
    
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        priceUSD: product.price,
        quantity: quantity,
      );
    }
    _saveGhostCart();
    notifyListeners();
  }

  // Convert guest cart to user cart after login
  void convertGuestToUser(String userId) {
    if (_isGuestCart && _items.isNotEmpty) {
      _currentUserId = userId;
      _isGuestCart = false;
      _saveCart();
    }
  }

void setUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _isGuestCart = false;
      _loadCart();
    }
  }

  Future<void> _loadCart() async {
    if (_currentUserId == null) return;
    try {
      final saved = await _storage.read(key: 'cart_${_currentUserId}');
      if (saved != null) {
        final List<dynamic> data = jsonDecode(saved);
        _items.clear();
        for (final item in data) {
          _items[item['productId']] = CartItem(
            productId: item['productId'],
            name: item['name'],
            price: item['price'],
            quantity: item['quantity'],
          );
        }
        notifyListeners();
      }
    } catch (e) {
      // Start fresh
    }
  }

  Future<void> _saveCart() async {
    if (_currentUserId == null) return;
    final data = _items.values.map((item) => {
      'productId': item.productId,
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
    }).toList();
    await _storage.write(key: 'cart_${_currentUserId ?? "guest"}', value: jsonEncode(data));
  }

  Future<void> _saveGhostCart() async {
    final data = _items.values.map((item) => {
      'productId': item.productId,
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
    }).toList();
    await _storage.write(key: 'cart_guest', value: jsonEncode(data));
  }

  Future<void> _loadGhostCart() async {
    try {
      final saved = await _storage.read(key: 'cart_guest');
      if (saved != null) {
        final List<dynamic> data = jsonDecode(saved);
        _items.clear();
        for (final item in data) {
          _items[item['productId']] = CartItem(
            productId: item['productId'],
            name: item['name'],
            price: item['price'],
            quantity: item['quantity'],
          );
        }
        notifyListeners();
      }
    } catch (e) {
      // Start fresh
    }
  }

  void addToCart(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: quantity,
      );
    }
    notifyListeners();
    _saveCart();
  }

  void removeFromCart(int productId) {
    _items.remove(productId);
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(int productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.quantity = quantity;
      }
      notifyListeners();
      _saveCart();
    }
  }

  void incrementQuantity(int productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      notifyListeners();
      _saveCart();
    }
  }

  void decrementQuantity(int productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
      _saveCart();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }
}