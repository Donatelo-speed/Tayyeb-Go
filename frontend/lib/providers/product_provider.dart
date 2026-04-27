import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _selectedCategory;
  String _searchQuery = '';

  List<Product> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get selectedCategory => _selectedCategory;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) _currentPage = 1;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final data = await _api.getProducts(
        category: _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage
      );
      
      final list = (data['products'] as List).map((p) => Product.fromJson(p)).toList();
      if (refresh || _currentPage == 1) {
        _products = list;
      } else {
        _products.addAll(list);
      }
      
      final pagination = data['pagination'] ?? {};
      _totalPages = pagination['totalPages'] ?? 1;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      loadDummyProducts();
    }
  }

  Future<void> loadCategories() async {
    try {
      final data = await _api.getCategories();
      _categories = (data['categories'] as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    loadProducts(refresh: true);
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    loadProducts(refresh: true);
  }

  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    loadProducts(refresh: true);
  }

  void loadDummyProducts() {
    _products = [
      Product(id: 1, name: 'Fresh Apples', description: 'Organic red apples', price: 3.99, stockQuantity: 50, category: 'Fruits'),
      Product(id: 2, name: 'Bananas', description: 'Fresh bananas', price: 1.49, stockQuantity: 100, category: 'Fruits'),
      Product(id: 3, name: 'Organic Milk', description: 'Fresh organic milk 1L', price: 4.99, stockQuantity: 30, category: 'Dairy'),
      Product(id: 4, name: 'Whole Bread', description: 'Fresh baked bread', price: 2.99, stockQuantity: 20, category: 'Bakery'),
      Product(id: 5, name: 'Tomatoes', description: 'Fresh red tomatoes', price: 2.49, stockQuantity: 40, category: 'Vegetables'),
      Product(id: 6, name: 'Orange Juice', description: 'Fresh squeezed juice', price: 3.49, stockQuantity: 25, category: 'Beverages'),
      Product(id: 7, name: 'Chicken Breast', description: 'Fresh chicken', price: 7.99, stockQuantity: 15, category: 'Meat'),
      Product(id: 8, name: 'Greek Yogurt', description: 'Creamy yogurt', price: 2.99, stockQuantity: 35, category: 'Dairy'),
      Product(id: 9, name: 'Potatoes', description: 'Fresh potatoes 1kg', price: 1.99, stockQuantity: 60, category: 'Vegetables'),
      Product(id: 10, name: 'Eggs', description: 'Farm fresh eggs (12)', price: 3.99, stockQuantity: 40, category: 'Dairy'),
      Product(id: 11, name: 'Strawberries', description: 'Fresh strawberries', price: 4.99, stockQuantity: 20, category: 'Fruits'),
      Product(id: 12, name: 'Cucumber', description: 'Fresh cucumbers', price: 1.29, stockQuantity: 45, category: 'Vegetables'),
    ];
    notifyListeners();
  }
}