import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/product.dart';
import '../models/modifier.dart';
import '../models/cart_line_item.dart';
import '../di/app_locator.dart';
import '../services/guest_mode_service.dart';
import '../../domain/entities/zone.dart';
import '../../domain/value_objects/geo_location.dart';
import '../../infrastructure/services/pricing_engine.dart';

const _uuid = Uuid();

class CartProvider extends ChangeNotifier {
  final Map<String, CartLineItem> _lines = {};
  static const String _prefsKey = 'cart_data';
  static const String _guestPrefsKey = 'guest_cart';
  final GuestModeService _guestModeService = GuestModeService();
  bool _isGuest = false;

  CartProvider() {
    _loadFromPrefs();
  }

  bool get isGuest => _isGuest;

  void setGuest(bool value) {
    _isGuest = value;
    _loadFromPrefs();
  }

  String get _activePrefsKey => _isGuest ? _guestPrefsKey : _prefsKey;

  String? _restaurantId;
  String? _restaurantName;
  double? _commissionPercent;
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  double _deliveryOverrideFee = -1.0;
  double _taxRate = AppConstants.taxRate;
  ZoneModel? _zone;
  GeoLocation? _restaurantLocation;
  GeoLocation? _deliveryLocation;
  bool _isSubscriber = false;
  PricingResult? _pricingResult;

  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  double? get commissionPercent => _commissionPercent;
  ZoneModel? get zone => _zone;
  PricingResult? get pricingResult => _pricingResult;

  List<CartLineItem> get lines => _lines.values.toList();
  int get totalQuantity =>
      _lines.values.fold(0, (sum, l) => sum + l.quantity);
  double get subtotal =>
      _lines.values.fold(0.0, (sum, l) => sum + l.lineTotal);
  double get deliveryFee {
    if (_deliveryOverrideFee >= 0) return _deliveryOverrideFee;
    // Use PricingEngine if zone + locations are set
    if (_zone != null && _restaurantLocation != null && _deliveryLocation != null) {
      final engine = PricingEngine();
      _pricingResult = engine.calculate(
        subtotal: subtotal,
        restaurantLocation: _restaurantLocation!,
        deliveryLocation: _deliveryLocation!,
        zone: _zone,
        discount: _couponDiscount,
        isSubscriber: _isSubscriber,
      );
      return _pricingResult!.deliveryFee;
    }
    // Fallback to flat fee
    return subtotal >= AppConstants.freeDeliveryThreshold ? 0.0 : AppConstants.deliveryFee;
  }
  double get tax => subtotal * _taxRate;
  double get promoDiscount => _couponDiscount;
  double get grandTotal {
    if (_pricingResult != null) return _pricingResult!.grandTotal;
    return (subtotal + deliveryFee + tax - _couponDiscount).clamp(0.0, double.infinity);
  }
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
      'zone_id': _zone?.id,
      'restaurant_lat': _restaurantLocation?.latitude,
      'restaurant_lng': _restaurantLocation?.longitude,
      'delivery_lat': _deliveryLocation?.latitude,
      'delivery_lng': _deliveryLocation?.longitude,
      'is_subscriber': _isSubscriber,
    };
    await prefs.setString(_activePrefsKey, jsonEncode(data));
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_activePrefsKey);
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

  Future<String?> mergeGuestCartWithUser(String userId) async {
    final guestItems = await _guestModeService.mergeGuestCartWithUser(userId);
    for (final item in guestItems) {
      final line = CartLineItem.fromJson(item);
      final existing = _lines.values
          .where((l) => l.hasSameConfigAs(line.product, line.selectedModifiers))
          .firstOrNull;
      if (existing != null) {
        _lines[existing.lineId] = existing.copyWith(
          quantity: existing.quantity + line.quantity,
        );
      } else {
        _lines[line.lineId] = line;
      }
    }
    _isGuest = false;
    notifyListeners();
    await _saveToPrefs();
    return null;
  }

  Future<String?> applyCoupon(String code, {String? customerId, String? phone}) async {
    if (code.trim().isEmpty) return 'Enter a coupon code';
    try {
      final promo = await AppLocator.instance.promotionLookup.validateCoupon(code);
      if (promo == null) return 'Invalid or expired coupon';

      final type = promo['type'] as String? ?? 'percentage';
      final value = (promo['value'] as num?)?.toDouble() ?? 0;
      final minOrder = (promo['minOrderAmount'] as num?)?.toDouble() ??
          (promo['minOrder'] as num?)?.toDouble() ?? 0;
      final maxDiscount = (promo['maxDiscountAmount'] as num?)?.toDouble() ??
          (promo['maxDiscount'] as num?)?.toDouble();
      final expiryDate = (promo['expiryDate'] as Timestamp?)?.toDate() ??
          (promo['expiresAt'] as Timestamp?)?.toDate();
      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
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

  void setZone(ZoneModel? zone) {
    _zone = zone;
    notifyListeners();
  }

  void setLocations({GeoLocation? restaurant, GeoLocation? delivery}) {
    if (restaurant != null) _restaurantLocation = restaurant;
    if (delivery != null) _deliveryLocation = delivery;
    notifyListeners();
  }

  void setSubscriber(bool value) {
    _isSubscriber = value;
    notifyListeners();
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
