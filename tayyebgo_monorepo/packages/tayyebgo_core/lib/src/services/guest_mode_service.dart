import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GuestModeService {
  static const String _guestCartKey = 'guest_cart';
  static const String _guestStateKey = 'is_guest';

  bool _isGuest = false;

  bool get isGuest => _isGuest;

  GuestModeService() {
    _loadGuestState();
  }

  Future<void> _loadGuestState() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool(_guestStateKey) ?? false;
  }

  Future<void> _saveGuestState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestStateKey, _isGuest);
  }

  Future<void> enterGuestMode() async {
    _isGuest = true;
    await _saveGuestState();
  }

  Future<void> exitGuestMode() async {
    _isGuest = false;
    await _saveGuestState();
    await clearGuestCart();
  }

  Future<void> addToGuestCart(Map<String, dynamic> item) async {
    final cart = await getGuestCart();
    final existingIndex = cart.indexWhere(
      (e) => e['line_id'] == item['line_id'],
    );
    if (existingIndex >= 0) {
      final existing = cart[existingIndex];
      final currentQty = (existing['quantity'] as num?)?.toInt() ?? 1;
      final addQty = (item['quantity'] as num?)?.toInt() ?? 1;
      cart[existingIndex] = {
        ...existing,
        'quantity': currentQty + addQty,
      };
    } else {
      cart.add(item);
    }
    await _saveGuestCart(cart);
  }

  Future<void> removeFromGuestCart(String itemId) async {
    final cart = await getGuestCart();
    cart.removeWhere((e) => e['line_id'] == itemId);
    await _saveGuestCart(cart);
  }

  Future<List<Map<String, dynamic>>> getGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestCartKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveGuestCart(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestCartKey, jsonEncode(cart));
  }

  Future<void> clearGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestCartKey);
  }

  Future<List<Map<String, dynamic>>> mergeGuestCartWithUser(String userId) async {
    final guestCart = await getGuestCart();
    await clearGuestCart();
    _isGuest = false;
    await _saveGuestState();
    return guestCart;
  }
}
