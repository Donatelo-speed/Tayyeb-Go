import 'package:flutter/material.dart';
import '../models/product.dart';

class WishlistProvider extends ChangeNotifier {
  List<Product> _items = [];
  bool _isLoading = false;

  List<Product> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  bool isInWishlist(int productId) => _items.any((p) => p.id == productId);

  void addToWishlist(Product product) {
    if (!isInWishlist(product.id)) {
      _items.add(product);
      notifyListeners();
    }
  }

  void removeFromWishlist(int productId) {
    _items.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void toggleWishlist(Product product) {
    if (isInWishlist(product.id)) {
      _items.removeWhere((p) => p.id == product.id);
    } else {
      _items.add(product);
    }
    notifyListeners();
  }
}