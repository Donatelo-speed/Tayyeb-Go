import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/driver_status_provider.dart';
import 'api_service.dart';

/// Drop this file over the existing api_service.dart — it extends the class
/// with every new method referenced by the three priority providers.
/// All existing methods in api_service.dart are preserved unchanged.

/// Base URL reads from the compile-time env or falls back to localhost.
const _base = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000/api',
);

extension TayyebgoApiExtensions on ApiService {
  // ─── Cart sync ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCart() async {
    final res = await _get('/cart');
    return res;
  }

  Future<void> syncCart(Map<String, dynamic> payload) async {
    await _post('/cart/sync', payload);
  }

  Future<void> clearCart() async {
    await _delete('/cart');
  }

  /// Creates an order — v2 accepts the full modifier-aware payload.
  Future<Map<String, dynamic>> createOrderV2(
      Map<String, dynamic> payload) async {
    return await _post('/orders/v2', payload);
  }

  // ─── Storefront theme ──────────────────────────────────────────────────────

  Future<dynamic> getStorefrontTheme(String vendorId) async {
    return await _get('/storefront/$vendorId');
  }

  Future<void> saveStorefrontTheme(
      String vendorId, Map<String, dynamic> payload) async {
    await _put('/storefront/$vendorId', payload);
  }

  // ─── Driver status ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDriverStatus() async {
    return await _get('/driver/status');
  }

  Future<void> setDriverOnline(bool online, {DriverPosition? position}) async {
    await _post('/driver/status', {
      'is_online': online,
      if (position != null) 'lat': position.lat,
      if (position != null) 'lng': position.lng,
    });
  }

  Future<void> broadcastDriverLocation(DriverPosition pos) async {
    await _post('/driver/location', {
      'lat':      pos.lat,
      'lng':      pos.lng,
      'accuracy': pos.accuracy,
      'heading':  pos.heading,
    });
  }

  /// Returns `null` if no order is waiting, otherwise the raw order map.
  Future<Map<String, dynamic>?> pollIncomingOrder() async {
    final data = await _get('/driver/order/incoming');
    if (data['order'] == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> acceptDriverOrder(String orderId) async {
    await _post('/driver/order/$orderId/accept', {});
  }

  Future<void> rejectDriverOrder(String orderId) async {
    await _post('/driver/order/$orderId/reject', {});
  }

  Future<void> completeDelivery(
    String orderId, {
    String? proofUrl,
    String? signature,
    DriverPosition? position,
  }) async {
    await _post('/driver/order/$orderId/complete', {
      'proof_url': proofUrl,
      'signature': signature,
      if (position != null) 'lat': position.lat,
      if (position != null) 'lng': position.lng,
    });
  }

  Future<Map<String, dynamic>> getDriverEarnings() async {
    return await _get('/driver/earnings');
  }

  // ─── Products with modifiers ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVendorProducts(String vendorId) async {
    return await _get('/vendors/$vendorId/products');
  }

  Future<Map<String, dynamic>> getProductModifiers(
    String vendorId,
    String productId,
  ) async {
    return await _get('/vendors/$vendorId/products/$productId/modifiers');
  }

  Future<Map<String, dynamic>> createModifierGroup(
    String vendorId,
    String productId,
    Map<String, dynamic> payload,
  ) async {
    return await _post(
        '/vendors/$vendorId/products/$productId/modifiers', payload);
  }

  Future<Map<String, dynamic>> updateModifierGroup(
    String vendorId,
    String productId,
    String groupId,
    Map<String, dynamic> payload,
  ) async {
    return await _put(
        '/vendors/$vendorId/products/$productId/modifiers/$groupId', payload);
  }

  Future<void> deleteModifierGroup(
    String vendorId,
    String productId,
    String groupId,
  ) async {
    await _delete(
        '/vendors/$vendorId/products/$productId/modifiers/$groupId');
  }

  Future<Map<String, dynamic>> patchModifierOption(
    String vendorId,
    String productId,
    String groupId,
    String optionId,
    Map<String, dynamic> payload,
  ) async {
    return await _patch(
        '/vendors/$vendorId/products/$productId/modifiers/$groupId/options/$optionId',
        payload);
  }

  Future<void> updateUpsellLinks(
    String vendorId,
    String productId,
    List<Map<String, dynamic>> links,
  ) async {
    await _put(
        '/vendors/$vendorId/products/$productId/modifiers/upsell',
        {'links': links});
  }

  // ─── Order status update (for driver pipeline) ─────────────────────────────

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _patch('/orders/$orderId/status', {'status': status});
  }

  // ─── Internal HTTP helpers ─────────────────────────────────────────────────

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type':  'application/json',
        'Accept':        'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _token();
    final res   = await http.get(
      Uri.parse('$_base$path'),
      headers: _headers(token),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final token = await _token();
    final res   = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers(token),
      body:    jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    final token = await _token();
    final res   = await http.put(
      Uri.parse('$_base$path'),
      headers: _headers(token),
      body:    jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> _patch(
      String path, Map<String, dynamic> body) async {
    final token = await _token();
    final res   = await http.patch(
      Uri.parse('$_base$path'),
      headers: _headers(token),
      body:    jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> _delete(String path) async {
    final token = await _token();
    final res   = await http.delete(
      Uri.parse('$_base$path'),
      headers: _headers(token),
    );
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Request failed (${res.statusCode})');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(
          body['error'] ?? 'Request failed (${res.statusCode})');
    }
    return body is Map<String, dynamic> ? body : {'data': body};
  }
}
