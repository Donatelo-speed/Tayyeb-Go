import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/product.dart';
import '../models/modifier.dart';
import '../models/cart_line_item.dart';

const _uuid = Uuid();

class CartProvider extends ChangeNotifier {
  final Map<String, CartLineItem> _lines = {};
  static const String _prefsKey = 'cart_data';

  CartProvider() {
    _loadFromPrefs();
  }

  String? _restaurantId;
  String? _restaurantName;
  double? _commissionPercent;
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  double _deliveryOverrideFee = -1.0;
  double _taxRate = AppConstants.taxRate;

  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  double? get commissionPercent => _commissionPercent;

  List<CartLineItem> get lines => _lines.values.toList();
  int get totalQuantity =>
      _lines.values.fold(0, (sum, l) => sum + l.quantity);
  double get subtotal =>
      _lines.values.fold(0.0, (sum, l) => sum + l.lineTotal);
  double get deliveryFee =>
      _deliveryOverrideFee >= 0 ? _deliveryOverrideFee : (subtotal > AppConstants.freeDeliveryThreshold ? 0.0 : AppConstants.deliveryFee);
  double get tax => subtotal * _taxRate;
  double get promoDiscount => _couponDiscount;
  double get grandTotal =>
      (subtotal + deliveryFee + tax - _couponDiscount).clamp(0.0, double.infinity);
  bool get isEmpty => _lines.isEmpty;
  String? get appliedCoupon => _appliedCouponCode;
  double get taxRate => _taxRate;

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'lines': _lines.values.map((l) => l.toJson()).toList(),
      'restaurant_id': _restaurantId,
      'restaurant_name': _restaurantName,
      'commission_percent': _commissionPercent,
      'coupon_code': _appliedCouponCode,
      'coupon_discount': _couponDiscount,
      'delivery_override_fee': _deliveryOverrideFee,
      'tax_rate': _taxRate,
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final linesList = data['lines'] as List<dynamic>? ?? [];
      _lines.clear();
      for (final item in linesList) {
        final line = CartLineItem.fromJson(item as Map<String, dynamic>);
        _lines[line.lineId] = line;
      }
      _restaurantId = data['restaurant_id'] as String?;
      _restaurantName = data['restaurant_name'] as String?;
      _commissionPercent = data['commission_percent'] as double?;
      _appliedCouponCode = data['coupon_code'] as String?;
      _couponDiscount = (data['coupon_discount'] as num?)?.toDouble() ?? 0.0;
      _deliveryOverrideFee = (data['delivery_override_fee'] as num?)?.toDouble() ?? -1.0;
      _taxRate = (data['tax_rate'] as num?)?.toDouble() ?? AppConstants.taxRate;
      notifyListeners();
    } catch (_) {}
  }

  void setRestaurant(String id, String name, {double commissionPercent = AppConstants.commissionPercent}) {
    _restaurantId = id;
    _restaurantName = name;
    _commissionPercent = commissionPercent;
    notifyListeners();
    _saveToPrefs();
  }

  bool isInCart(int productId) =>
      _lines.values.any((l) => l.product.id == productId);

  int quantityOf(int productId) =>
      _lines.values
          .where((l) => l.product.id == productId)
          .fold(0, (sum, l) => sum + l.quantity);

  void addLine(
    Product product, {
    int quantity = 1,
    List<SelectedModifierGroup> modifiers = const [],
    String? customerNote,
  }) {
    final existing = _lines.values
        .where((l) => l.hasSameConfigAs(product, modifiers))
        .firstOrNull;
    if (existing != null) {
      _lines[existing.lineId] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      final id = _uuid.v4();
      _lines[id] = CartLineItem(
        lineId: id,
        product: product,
        quantity: quantity,
        selectedModifiers: modifiers,
        customerNote: customerNote,
      );
    }
    notifyListeners();
    _saveToPrefs();
  }

  void removeLine(String lineId) {
    _lines.remove(lineId);
    notifyListeners();
    _saveToPrefs();
  }

  void incrementLine(String lineId) {
    final line = _lines[lineId];
    if (line != null) {
      _lines[lineId] = line.copyWith(quantity: line.quantity + 1);
      notifyListeners();
      _saveToPrefs();
    }
  }

  void decrementLine(String lineId) {
    final line = _lines[lineId];
    if (line == null) return;
    if (line.quantity <= 1) {
      removeLine(lineId);
    } else {
      _lines[lineId] = line.copyWith(quantity: line.quantity - 1);
      notifyListeners();
      _saveToPrefs();
    }
  }

  void updateLineNote(String lineId, String note) {
    final line = _lines[lineId];
    if (line != null) {
      _lines[lineId] = line.copyWith(
          customerNote: note.trim().isEmpty ? null : note.trim());
      notifyListeners();
      _saveToPrefs();
    }
  }

  Future<void> clearCart() async {
    _lines.clear();
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    _restaurantId = null;
    _restaurantName = null;
    _commissionPercent = null;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<String?> applyCoupon(String code) async {
    if (code.trim().isEmpty) return 'Enter a coupon code';
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promos')
          .where('code', isEqualTo: code.trim().toUpperCase())
          .where('active', isEqualTo: true)
          .get();
      if (snapshot.docs.isEmpty) return 'Invalid or expired coupon';
      final promo = snapshot.docs.first.data();
      final type = promo['type'] as String? ?? 'percentage';
      final value = (promo['value'] as num?)?.toDouble() ?? 0;
      final minOrder = (promo['minOrder'] as num?)?.toDouble() ?? 0;
      final maxDiscount = (promo['maxDiscount'] as num?)?.toDouble();
      final expiresAt = promo['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        return 'This coupon has expired';
      }
      if (subtotal < minOrder) {
        return 'Minimum order of \$${minOrder.toStringAsFixed(2)} required';
      }
      double discount;
      if (type == 'percentage') {
        discount = subtotal * (value / 100);
        if (maxDiscount != null && discount > maxDiscount) {
          discount = maxDiscount;
        }
      } else {
        discount = value;
      }
      _appliedCouponCode = code.trim().toUpperCase();
      _couponDiscount = discount;
      notifyListeners();
      _saveToPrefs();
      return null;
    } catch (e) {
      return 'Failed to validate coupon';
    }
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    notifyListeners();
    _saveToPrefs();
  }

  void setDeliveryFee(double fee) {
    _deliveryOverrideFee = fee;
    notifyListeners();
    _saveToPrefs();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
    _saveToPrefs();
  }

  Map<String, dynamic> buildCheckoutPayload({
    required String deliveryAddressId,
    required String paymentMethod,
    String? specialInstructions,
    String? timeSlotId,
  }) {
    return {
      'items': _lines.values.map((l) => l.toJson()).toList(),
      'delivery_address_id': deliveryAddressId,
      'payment_method': paymentMethod,
      'special_instructions': specialInstructions,
      'time_slot_id': timeSlotId,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'discount': _couponDiscount,
      'coupon_code': _appliedCouponCode,
      'grand_total': grandTotal,
    };
  }

  void clearError() {}

  List<Map<String, String>> getSuggestedCombos(List<Map<String, dynamic>> menuItems) {
    final currentProductIds = _lines.values.map((l) => l.product.id).toSet();
    final suggestions = <Map<String, String>>[];
    for (final item in menuItems) {
      final tags = (item['tags'] as List<dynamic>?)?.map((t) => t.toString()).toSet() ?? {};
      if (tags.contains('frequently_bought_together')) {
        final relatedIds = (item['pairedWith'] as List<dynamic>?)?.map((t) => t.toString()).toSet() ?? {};
        final missing = relatedIds.difference(currentProductIds);
        if (missing.isNotEmpty) {
          suggestions.add({
            'productId': item['id'] as String? ?? '',
            'name': item['name'] as String? ?? '',
            'price': (item['price'] as num?)?.toString() ?? '0',
          });
        }
      }
    }
    return suggestions;
  }

  List<String> getUnavailableWarnings(List<Map<String, dynamic>> menuItems) {
    final warnings = <String>[];
    final productMap = {for (final m in menuItems) m['id'] as String: m};
    for (final line in _lines.values) {
      final menuItem = productMap[line.product.id];
      if (menuItem != null) {
        final isAvailable = menuItem['isAvailable'] as bool? ?? true;
        if (!isAvailable) {
          warnings.add('${line.product.name} is no longer available');
        }
      }
    }
    return warnings;
  }

  bool hasItemsFrom(String restaurantId) => _restaurantId == restaurantId;
}
