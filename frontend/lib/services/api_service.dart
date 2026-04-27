import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  final _storage = const FlutterSecureStorage();
  
  Future<String?> getToken() async => await _storage.read(key: 'auth_token');
  
  Future<void> saveToken(String token) async => await _storage.write(key: 'auth_token', value: token);
  
  Future<void> deleteToken() async => await _storage.delete(key: 'auth_token');
  
  Map<String, String> _headers({String? token}) {
    final h = {'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }
  
  Map<String, dynamic> _parse(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body);
    }
    throw Exception(jsonDecode(resp.body)['error'] ?? 'Request failed');
  }
  
  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password})
    );
    final data = _parse(resp);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }
  
  Future<Map<String, dynamic>> register(String email, String password, String name, {String? phone}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password, 'name': name, 'phone': phone})
    );
    final data = _parse(resp);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }
  
  Future<Map<String, dynamic>> me() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  // Products
  Future<Map<String, dynamic>> getProducts({String? category, String? search, int page = 1}) async {
    final params = <String, String>{'page': '$page', 'limit': '20'};
    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;
    
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers());
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> getProduct(int id) async {
    final resp = await http.get(Uri.parse('$baseUrl/products/$id'), headers: _headers());
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> getCategories() async {
    final resp = await http.get(Uri.parse('$baseUrl/categories'), headers: _headers());
    return _parse(resp);
  }
  
  // Cart
  Future<Map<String, dynamic>> getCart() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/cart'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> addToCart(int productId, {int quantity = 1}) async {
    final token = await getToken();
    final resp = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: _headers(token: token),
      body: jsonEncode({'productId': productId, 'quantity': quantity})
    );
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> removeFromCart(int productId) async {
    final token = await getToken();
    final resp = await http.delete(Uri.parse('$baseUrl/cart/$productId'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> clearCart() async {
    final token = await getToken();
    final resp = await http.delete(Uri.parse('$baseUrl/cart'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  // Orders
  Future<Map<String, dynamic>> createOrder(List<Map<String, dynamic>> items, String address, String phone, {String? notes}) async {
    final token = await getToken();
    final resp = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers(token: token),
      body: jsonEncode({
        'items': items,
        'deliveryAddress': address,
        'deliveryPhone': phone,
        'notes': notes
      })
    );
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> getOrders() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/orders'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> getOrder(int id) async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/orders/$id'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  // Wishlist
  Future<Map<String, dynamic>> getWishlist() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/wishlist'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> addToWishlist(int productId) async {
    final token = await getToken();
    final resp = await http.post(
      Uri.parse('$baseUrl/wishlist'),
      headers: _headers(token: token),
      body: jsonEncode({'productId': productId})
    );
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> removeFromWishlist(int productId) async {
    final token = await getToken();
    final resp = await http.delete(Uri.parse('$baseUrl/wishlist/$productId'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  // Admin Stats
  Future<Map<String, dynamic>> getAdminStats() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/admin/stats'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> getAdminUsers() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/admin/users'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> getAdminProducts() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/admin/products'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> updateProduct(int id, {double? price, int? stock}) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (price != null) body['price'] = price;
    if (stock != null) body['stock'] = stock;
    
    final resp = await http.put(
      Uri.parse('$baseUrl/admin/products/$id'),
      headers: _headers(token: token),
      body: jsonEncode(body)
    );
    return _parse(resp);
  }
  
  // Delivery
  Future<Map<String, dynamic>> getDeliveryOrders() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/delivery/orders'), headers: _headers(token: token));
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    final token = await getToken();
    final resp = await http.post(
      Uri.parse('$baseUrl/delivery/accept'),
      headers: _headers(token: token),
      body: jsonEncode({'orderId': orderId})
    );
    return _parse(resp);
  }
  
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    final token = await getToken();
    final resp = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: _headers(token: token),
      body: jsonEncode({'status': status})
    );
    return _parse(resp);
  }
  
  // Delivery Application
  Future<Map<String, dynamic>> submitDeliveryApplication(Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/delivery/apply'),
      headers: _headers(),
      body: jsonEncode(data)
    );
    return _parse(resp);
  }
  
  // Get Admin Delivery Applications
  Future<List<dynamic>> getDeliveryApplications() async {
    final token = await getToken();
    final resp = await http.get(Uri.parse('$baseUrl/admin/delivery-applications'), headers: _headers(token: token));
    final data = _parse(resp);
    return data['applications'] ?? [];
  }
  
  // Approve/Reject Delivery Application
  Future<Map<String, dynamic>> respondToApplication(int id, String status, {String? message}) async {
    final token = await getToken();
    final resp = await http.post(
      Uri.parse('$baseUrl/admin/delivery-applications/$id'),
      headers: _headers(token: token),
      body: jsonEncode({'status': status, 'message': message})
    );
    return _parse(resp);
  }
}