import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/product.dart';

class WishlistProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<int, Product> _items = {};
  String? _currentUserId;

  List<Product> get products => _items.values.toList();
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool isInWishlist(int productId) => _items.containsKey(productId);

  void setUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _loadWishlist();
    }
  }

  Future<void> _loadWishlist() async {
    if (_currentUserId == null) return;
    try {
      final saved = await _storage.read(key: 'wishlist_${_currentUserId}');
      if (saved != null) {
        final List<dynamic> data = jsonDecode(saved);
        _items.clear();
        for (final item in data) {
          _items[item['id']] = Product.fromJson(item);
        }
        notifyListeners();
      }
    } catch (e) {
      // Start fresh
    }
  }

  Future<void> _saveWishlist() async {
    if (_currentUserId == null) return;
    final data = _items.values.map((p) => p.toJson()).toList();
    await _storage.write(key: 'wishlist_${_currentUserId}', value: jsonEncode(data));
  }

  void addToWishlist(Product product) {
    _items[product.id] = product;
    notifyListeners();
    _saveWishlist();
  }

  void removeFromWishlist(int productId) {
    _items.remove(productId);
    notifyListeners();
    _saveWishlist();
  }

  void toggleWishlist(Product product) {
    if (isInWishlist(product.id)) {
      removeFromWishlist(product.id);
    } else {
      addToWishlist(product);
    }
  }

  void clearWishlist() {
    _items.clear();
    notifyListeners();
    _saveWishlist();
  }
}