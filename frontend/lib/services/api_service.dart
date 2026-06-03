import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API GET Error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API POST Error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API PUT Error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API PATCH Error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API DELETE Error: $e');
      return {'error': e.toString()};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      return jsonDecode(response.body);
    } else {
      return {
        'error': 'Request failed',
        'statusCode': response.statusCode,
        'message': response.body,
      };
    }
  }

  // ── Cart endpoints (stubs — will be implemented when backend is ready) ──────

  Future<Map<String, dynamic>> syncCart(Map<String, dynamic> payload) async {
    try {
      return await post('/cart/sync', payload);
    } catch (_) {
      return {'success': true, 'synced': false};
    }
  }

  Future<Map<String, dynamic>> clearCart() async {
    try {
      return await delete('/cart');
    } catch (_) {
      return {'success': true, 'cleared': false};
    }
  }

  Future<Map<String, dynamic>> getCart() async {
    try {
      return await get('/cart');
    } catch (_) {
      return {'lines': []};
    }
  }

  Future<Map<String, dynamic>> createOrderV2(Map<String, dynamic> payload) async {
    try {
      return await post('/orders', payload);
    } catch (_) {
      // In demo mode the checkout flow uses Firestore directly.
      return {'success': true, 'orderId': 'demo-${DateTime.now().millisecondsSinceEpoch}'};
    }
  }
}