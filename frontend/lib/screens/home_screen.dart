import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'orders_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'delivery/delivery_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() { super.initState(); _loadInitialData(); }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      
      // Set user for cart and wishlist
      if (authProvider.user != null) {
        final userId = authProvider.user!.id.toString();
        cartProvider.setUser(userId);
        wishlistProvider.setUser(userId);
      }
      
      Provider.of<ProductProvider>(context, listen: false).loadProducts(refresh: true);
      Provider.of<ProductProvider>(context, listen: false).loadCategories();
    });
  }

  List<Widget> _buildScreens(AuthProvider authProvider) {
    final screens = <Widget>[
      const CatalogScreen(),
      const CartScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
    if (authProvider.isAdmin) {
      screens.insert(3, const AdminDashboardScreen());
    }
    if (authProvider.isDelivery) {
      screens.insert(authProvider.isAdmin ? 4 : 3, const DeliveryOrdersScreen());
    }
    return screens;
  }

  List<NavigationDestination> _buildDestinations(AuthProvider authProvider, CartProvider cartProvider) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Badge(label: Text('${cartProvider.itemCount}'), isLabelVisible: cartProvider.itemCount > 0, child: const Icon(Icons.shopping_cart)), label: 'Cart'),
      const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
    ];
    if (authProvider.isAdmin) {
      destinations.insert(3, const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
    }
    if (authProvider.isDelivery) {
      final insertIndex = authProvider.isAdmin ? 4 : 3;
      destinations.insert(insertIndex, const NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Deliveries'));
    }
    return destinations;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final screens = _buildScreens(authProvider);
    final destinations = _buildDestinations(authProvider, cartProvider);

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: destinations,
      ),
    );
  }
}