import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GuestModeService {
  static const String _guestIdKey = 'guest_device_id';
  static const String _guestCartKey = 'guest_cart';
  
  static String? _guestId;
  
  // Get or create guest ID
  static Future<String> getGuestId() async {
    if (_guestId != null) return _guestId!;
    
    final prefs = await SharedPreferences.getInstance();
    _guestId = prefs.getString(_guestIdKey);
    
    if (_guestId == null) {
      _guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_guestIdKey, _guestId!);
    }
    
    return _guestId!;
  }
  
  // Guest Cart Operations
  static Future<List<GuestCartItem>> getGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_guestCartKey);
    
    if (cartJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(cartJson);
      return decoded.map((item) => GuestCartItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<void> saveGuestCart(List<GuestCartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_guestCartKey, cartJson);
  }
  
  static Future<void> addToGuestCart(GuestCartItem item) async {
    final cart = await getGuestCart();
    
    // Check if same product with same modifiers exists
    final existingIndex = cart.indexWhere(
      (c) => c.productId == item.productId && _modifiersMatch(c.modifiers, item.modifiers),
    );
    
    if (existingIndex >= 0) {
      final e = cart[existingIndex];
      cart[existingIndex] = GuestCartItem(
        cartItemId: e.cartItemId,
        productId: e.productId,
        productName: e.productName,
        productNameAr: e.productNameAr,
        price: e.price,
        quantity: e.quantity + item.quantity,
        modifiers: e.modifiers,
        customRequest: e.customRequest,
        restaurantId: e.restaurantId,
        restaurantName: e.restaurantName,
      );
    } else {
      // Add new item
      cart.add(item);
    }
    
    await saveGuestCart(cart);
  }
  
  static Future<void> removeFromGuestCart(String itemId) async {
    final cart = await getGuestCart();
    cart.removeWhere((item) => item.cartItemId == itemId);
    await saveGuestCart(cart);
  }
  
  static Future<void> updateGuestCartItemQuantity(String itemId, int quantity) async {
    final cart = await getGuestCart();
    final index = cart.indexWhere((item) => item.cartItemId == itemId);
    
    if (index >= 0) {
      if (quantity <= 0) {
        cart.removeAt(index);
      } else {
        final e = cart[index];
        cart[index] = GuestCartItem(
          cartItemId: e.cartItemId,
          productId: e.productId,
          productName: e.productName,
          productNameAr: e.productNameAr,
          price: e.price,
          quantity: quantity,
          modifiers: e.modifiers,
          customRequest: e.customRequest,
          restaurantId: e.restaurantId,
          restaurantName: e.restaurantName,
        );
      }
    }
    
    await saveGuestCart(cart);
  }
  
  static Future<void> clearGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestCartKey);
  }
  
  static bool _modifiersMatch(List<CartModifier>? a, List<CartModifier>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i].groupName != b[i].groupName || a[i].optionName != b[i].optionName) {
        return false;
      }
    }
    return true;
  }
}

// =====================================================
// DATA MODELS
// =====================================================

class GuestCartItem {
  final String cartItemId;
  final String productId;
  final String productName;
  final String productNameAr;
  final double price;
  final int quantity;
  final List<CartModifier>? modifiers;
  final String? customRequest;
  final String? restaurantId;
  final String? restaurantName;
  
  GuestCartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.productNameAr,
    required this.price,
    required this.quantity,
    this.modifiers,
    this.customRequest,
    this.restaurantId,
    this.restaurantName,
  });
  
  double get totalPrice {
    double modPrice = modifiers?.fold<double>(0.0, (sum, m) => sum + m.price) ?? 0;
    return (price + modPrice) * quantity;
  }
  
  factory GuestCartItem.fromJson(Map<String, dynamic> json) {
    return GuestCartItem(
      cartItemId: json['cartItemId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productNameAr: json['productNameAr'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      modifiers: (json['modifiers'] as List<dynamic>?)
          ?.map((m) => CartModifier.fromJson(m))
          .toList(),
      customRequest: json['customRequest'],
      restaurantId: json['restaurantId'],
      restaurantName: json['restaurantName'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'cartItemId': cartItemId,
    'productId': productId,
    'productName': productName,
    'productNameAr': productNameAr,
    'price': price,
    'quantity': quantity,
    'modifiers': modifiers?.map((m) => m.toJson()).toList(),
    'customRequest': customRequest,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
  };
}

class CartModifier {
  final String groupName;
  final String groupNameAr;
  final String optionName;
  final String optionNameAr;
  final double price;
  
  CartModifier({
    required this.groupName,
    required this.groupNameAr,
    required this.optionName,
    required this.optionNameAr,
    required this.price,
  });
  
  factory CartModifier.fromJson(Map<String, dynamic> json) {
    return CartModifier(
      groupName: json['groupName'] ?? '',
      groupNameAr: json['groupNameAr'] ?? '',
      optionName: json['optionName'] ?? '',
      optionNameAr: json['optionNameAr'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'groupName': groupName,
    'groupNameAr': groupNameAr,
    'optionName': optionName,
    'optionNameAr': optionNameAr,
    'price': price,
  };
}

// =====================================================
// GUEST CART WIDGET
// =====================================================

class GuestCartBanner extends StatelessWidget {
  final int itemCount;
  final VoidCallback onCheckout;
  
  const GuestCartBanner({
    super.key,
    required this.itemCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade700,
            Colors.amber.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount items in cart',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Continue as guest or sign in to save',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.amber.shade700,
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CHECKOUT AUTH GATE
// =====================================================

class CheckoutAuthGate extends StatelessWidget {
  final VoidCallback onGuestCheckout;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  
  const CheckoutAuthGate({
    super.key,
    required this.onGuestCheckout,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_outline, color: Color(0xFF16A085)),
          SizedBox(width: 8),
          Text('Complete Your Order'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sign in to save your order history, earn loyalty points, and get faster checkout next time.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Continue as Guest
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGuestCheckout,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Continue as Guest'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Sign In
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Register
          TextButton(
            onPressed: onRegister,
            child: const Text("Don't have an account? Sign Up"),
          ),
        ],
      ),
    );
  }
}