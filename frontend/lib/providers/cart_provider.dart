import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/modifier.dart';
import '../models/cart_line_item.dart';
import '../services/api_service.dart';

const _uuid = Uuid();

class CartProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final Map<String, CartLineItem> _lines = {};

  bool _isLoading = false;
  String? _error;
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  double _deliveryOverrideFee = -1.0;
  double _taxRate = 0.08;

  List<CartLineItem> get lines => _lines.values.toList();

  int get totalQuantity =>
      _lines.values.fold(0, (sum, l) => sum + l.quantity);

  double get subtotal =>
      _lines.values.fold(0.0, (sum, l) => sum + l.lineTotal);

  double get deliveryFee => _deliveryOverrideFee >= 0
      ? _deliveryOverrideFee
      : subtotal > 50.0 ? 0.0 : 5.0;

  double get tax => subtotal * _taxRate;

  double get promoDiscount => _couponDiscount;

  double get grandTotal =>
      (subtotal + deliveryFee + tax - _couponDiscount).clamp(0.0, double.infinity);

  bool get isEmpty => _lines.isEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get appliedCoupon => _appliedCouponCode;
  double get taxRate => _taxRate;

  bool isInCart(int productId) =>
      _lines.values.any((l) => l.product.id == productId);

  int quantityOf(int productId) => _lines.values
      .where((l) => l.product.id == productId)
      .fold(0, (sum, l) => sum + l.quantity);

  Future<void> addLine(
    Product product, {
    int quantity = 1,
    List<SelectedModifierGroup> modifiers = const [],
    String? customerNote,
  }) async {
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
    _syncToApi();
  }

  void removeLine(String lineId) {
    _lines.remove(lineId);
    notifyListeners();
    _syncToApi();
  }

  void incrementLine(String lineId) {
    final line = _lines[lineId];
    if (line != null) {
      _lines[lineId] = line.copyWith(quantity: line.quantity + 1);
      notifyListeners();
      _syncToApi();
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
      _syncToApi();
    }
  }

  void updateLineNote(String lineId, String note) {
    final line = _lines[lineId];
    if (line != null) {
      _lines[lineId] = line.copyWith(
          customerNote: note.trim().isEmpty ? null : note.trim());
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _lines.clear();
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    notifyListeners();
    try {
      await _api.clearCart();
    } catch (_) {}
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
      return null;
    } catch (e) {
      return 'Failed to validate coupon';
    }
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    notifyListeners();
  }

  void setDeliveryFee(double fee) {
    _deliveryOverrideFee = fee;
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
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

  Future<bool> checkout({
    required String deliveryAddressId,
    required String paymentMethod,
    String? specialInstructions,
    String? timeSlotId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = buildCheckoutPayload(
        deliveryAddressId: deliveryAddressId,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
        timeSlotId: timeSlotId,
      );
      await _api.createOrderV2(payload);
      await clearCart();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncToApi() async {
    try {
      final payload = {
        'lines': _lines.values.map((l) => l.toJson()).toList(),
      };
      await _api.syncCart(payload);
    } catch (_) {}
  }

  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getCart();
      _lines.clear();
      final serverLines = data['lines'] as List? ?? [];
      for (final raw in serverLines) {
        final product = Product.fromJson(raw['product'] as Map<String, dynamic>);
        final lineId = raw['line_id']?.toString() ?? _uuid.v4();
        final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
        final note = raw['customer_note'] as String?;
        final rawMods = raw['selected_modifiers'] as List? ?? [];
        final mods = <SelectedModifierGroup>[];
        for (final rm in rawMods) {
          final groupId = rm['group_id']?.toString() ?? '';
          final matchingGroup = (product.modifierGroups ?? [])
              .firstWhere((g) => g.id == groupId, orElse: () {
            return ModifierGroup(
              id: groupId,
              name: rm['group_name'] ?? groupId,
              options: [],
            );
          });
          mods.add(SelectedModifierGroup(
            groupId: groupId,
            groupName: rm['group_name'] ?? '',
            selectedOptionIds:
                List<String>.from(rm['selected_option_ids'] as List? ?? []),
            group: matchingGroup,
          ));
        }
        _lines[lineId] = CartLineItem(
          lineId: lineId,
          product: product,
          quantity: qty,
          selectedModifiers: mods,
          customerNote: note,
        );
      }
    } catch (e) {
      _error = _extractMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractMessage(Object e) {
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return e.toString();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
