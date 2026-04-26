import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<String> _categories = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProducts = 0;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedSubCategory;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  double? _minPrice;
  double? _maxPrice;

  List<Product> get products => _products;
  List<String> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalProducts => _totalProducts;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedSubCategory => _selectedSubCategory;

  List<String> get uniqueCategories {
    final cats = _categories.toSet().toList();
    cats.sort();
    return cats;
  }

  List<String> getSubCategories(String category) {
    return [];
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) { _currentPage = 1; _products = []; }
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final response = await _apiService.getProducts(
        page: _currentPage, limit: 20, search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory, subCategory: _selectedSubCategory,
        sortBy: _sortBy, order: _sortOrder, minPrice: _minPrice, maxPrice: _maxPrice,
      );
      final productList = (response['products'] as List).map((p) => Product.fromJson(p)).toList();
      if (refresh) { _products = productList; } else { _products.addAll(productList); }
      _totalProducts = response['pagination']['total'];
      _totalPages = response['pagination']['totalPages'];
      _isLoading = false;
      notifyListeners();
    } catch (e) { _error = e.toString(); _isLoading = false; notifyListeners(); }
  }

  Future<void> loadCategories() async {
    try { _categories = await _apiService.fetchCategories(); notifyListeners(); } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  Future<void> loadProduct(int id) async {
    try { _isLoading = true; notifyListeners(); _selectedProduct = await _apiService.getProduct(id); _isLoading = false; notifyListeners(); }
    catch (e) { _error = e.toString(); _isLoading = false; notifyListeners(); }
  }

  void searchProducts(String query) { _searchQuery = query; loadProducts(refresh: true); }
  void filterByCategory(String? category) { _selectedCategory = category; loadProducts(refresh: true); }
  void sortProducts(String sortBy, bool ascending) { _sortBy = sortBy; _sortOrder = ascending ? 'asc' : 'desc'; loadProducts(refresh: true); }

  void setSearch(String query) { _searchQuery = query; loadProducts(refresh: true); }
  void setCategory(String? category) { if (_selectedCategory != category) { _selectedCategory = category; _selectedSubCategory = null; loadProducts(refresh: true); } }
  void setSubCategory(String? subCategory) { _selectedSubCategory = subCategory; loadProducts(refresh: true); }
  void setSort(String sortBy, String order) { _sortBy = sortBy; _sortOrder = order; loadProducts(refresh: true); }
  void setPriceRange(double? min, double? max) { _minPrice = min; _maxPrice = max; loadProducts(refresh: true); }
  void clearFilters() { _searchQuery = ''; _selectedCategory = null; _selectedSubCategory = null; _minPrice = null; _maxPrice = null; _sortBy = 'created_at'; _sortOrder = 'desc'; loadProducts(refresh: true); }
  void loadNextPage() { if (_currentPage < _totalPages && !_isLoading) { _currentPage++; loadProducts(); } }
  bool get hasMoreProducts => _currentPage < _totalPages;
}