import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/cart_provider.dart';
import '../models/user_model.dart';
import '../theme/tayyebgo_theme.dart';
import '../models/product.dart';
import '../widgets/shimmer_loading.dart';
import '../admin/admin_app.dart';
import '../screens/cashier/cashier_dashboard_screen.dart';
import '../driver/delivery_dashboard_screen.dart';
import '../screens/vendor/vendor_dashboard_screen.dart';
import '../customer/catalog_screen.dart';
import '../customer/vendors_screen.dart';
import '../customer/cart_screen.dart';
import '../customer/orders_screen.dart';
import '../customer/profile_screen.dart';
import '../common/universal_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isSuperAdmin) return const AdminApp();
    if (auth.isRestaurantOwner) {
      final vendorId = auth.user?.vendorId ?? 'vendor-1';
      return VendorDashboardScreen(
        vendorId: vendorId,
        vendorName: auth.user?.displayName ?? 'Restaurant',
      );
    }
    if (auth.isCashier) return const CashierDashboardScreen();
    if (auth.isDriver) return const DeliveryDashboardScreen();

    return CustomerHome(locale: context.watch<LocaleProvider>());
  }
}

class CustomerHome extends StatefulWidget {
  final LocaleProvider locale;
  const CustomerHome({super.key, required this.locale});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;

  final _screens = const [
    _HomeTab(),
    VendorsScreen(),
    CartScreen(),
    OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              selectedIndex: _currentIndex.clamp(0, 3),
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              extended: true,
              minExtendedWidth: 200,
              labelType: NavigationRailLabelType.none,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(gradient: TayyebGoTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                      child: Stack(alignment: Alignment.center, children: [
                        Icon(Icons.restaurant_menu, size: 24, color: Colors.white.withValues(alpha: 0.2)),
                        const Icon(Icons.delivery_dining, size: 28, color: Colors.white),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tayyeb-Go', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                const NavigationRailDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: Text('Vendors')),
                NavigationRailDestination(
                  icon: Badge(isLabelVisible: cart.totalQuantity > 0, label: Text('${cart.totalQuantity}'), child: const Icon(Icons.shopping_cart_outlined)),
                  selectedIcon: Badge(isLabelVisible: cart.totalQuantity > 0, label: Text('${cart.totalQuantity}'), child: const Icon(Icons.shopping_cart)),
                  label: const Text('Cart'),
                ),
                const NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: _screens[_currentIndex.clamp(0, 3)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: _DrawerMenu(
        onNavigate: (route) {
          Navigator.pop(context);
          _navigateToRoute(context, route);
        },
        locale: widget.locale,
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Vendors'),
          NavigationDestination(
            icon: Badge(isLabelVisible: cart.totalQuantity > 0, label: Text('${cart.totalQuantity}'), child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: Badge(isLabelVisible: cart.totalQuantity > 0, label: Text('${cart.totalQuantity}'), child: const Icon(Icons.shopping_cart)),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    final auth = context.read<AuthProvider>();
    final role = auth.user?.role;
    switch (route) {
      case 'profile':
        Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(userRole: role ?? UserRole.customer)));
      case 'settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      case 'privacy':
        Navigator.push(context, MaterialPageRoute(builder: (_) => _StaticPageView(title: 'Privacy Policy', body: 'Your privacy is important to us. We collect and use your data solely to process orders and improve our service. We do not share your personal information with third parties without your consent.')));
      case 'support':
        Navigator.push(context, MaterialPageRoute(builder: (_) => _StaticPageView(title: 'Support Center', body: 'Contact our support team:\n\nEmail: support@tayyebgo.com\nPhone: +1 (555) 000-0000\n\nHours: Mon–Fri, 9 AM – 6 PM')));
    }
  }
}

class _DrawerMenu extends StatelessWidget {
  final void Function(String route) onNavigate;
  final LocaleProvider locale;

  const _DrawerMenu({required this.onNavigate, required this.locale});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(gradient: TayyebGoTheme.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(Icons.person_outline, 'Profile Details', () => onNavigate('profile')),
                  _drawerTile(Icons.settings_outlined, 'System Settings', () => onNavigate('settings')),
                  const Divider(indent: 16, endIndent: 16),
                  _drawerTile(Icons.privacy_tip_outlined, 'Privacy Policy', () => onNavigate('privacy')),
                  _drawerTile(Icons.headset_mic_outlined, 'Support Center', () => onNavigate('support')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { auth.logout(context); },
                  icon: const Icon(Icons.logout, color: TayyebGoTheme.errorColor),
                  label: const Text('Logout', style: TextStyle(color: TayyebGoTheme.errorColor)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: TayyebGoTheme.errorColor)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: TayyebGoTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
      onTap: onTap,
    );
  }
}

class _StaticPageView extends StatelessWidget {
  final String title;
  final String body;
  const _StaticPageView({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: TayyebGoTheme.primaryColor, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 15, height: 1.6)),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text('Tayyeb-Go',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: TayyebGoTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: TayyebGoTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome to Tayyeb-Go!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Order your favorite food, delivered fast.',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Search for food...',
                      prefixIcon:
                          const Icon(Icons.search, color: TayyebGoTheme.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CatalogScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Row(
                      children: _defaultCategories.map((cat) {
                        final color = _parseColor(cat['color'] as String);
                        return _CatItem(
                          icon: _iconFromString(cat['icon'] as String),
                          label: cat['name'] as String,
                          color: color,
                        );
                      }).toList(),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Row(
                      children: [
                        ShimmerLoading(width: 60, height: 60, borderRadius: 16),
                        SizedBox(width: 12),
                        ShimmerLoading(width: 60, height: 60, borderRadius: 16),
                        SizedBox(width: 12),
                        ShimmerLoading(width: 60, height: 60, borderRadius: 16),
                      ],
                    );
                  }
                  final categories = snapshot.data!.docs.isNotEmpty
                      ? snapshot.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return {
                            'id': doc.id,
                            'name': d['name'] as String? ?? '',
                            'icon': d['icon'] as String? ?? 'fastfood',
                            'color': d['color'] as String? ?? '#FF9800',
                          };
                        }).toList()
                      : _defaultCategories;
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((cat) {
                      final color = _parseColor(cat['color'] as String);
                      return _CatItem(
                        icon: _iconFromString(cat['icon'] as String),
                        label: cat['name'] as String,
                        color: color,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CatalogScreen(
                                categoryFilter: cat['name'] as String),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Popular Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _PopularItemsGrid(),
          ],
        ),
      ),
    );
  }
}

const _defaultCategories = [
  {'name': 'Fast Food', 'icon': 'fastfood', 'color': '#FF9800'},
  {'name': 'Pizza', 'icon': 'local_pizza', 'color': '#F44336'},
  {'name': 'Breakfast', 'icon': 'breakfast_dining', 'color': '#FFC107'},
  {'name': 'Coffee', 'icon': 'local_cafe', 'color': '#795548'},
  {'name': 'Desserts', 'icon': 'cake', 'color': '#E91E63'},
  {'name': 'Noodles', 'icon': 'ramen_dining', 'color': '#9C27B0'},
  {'name': 'Seafood', 'icon': 'set_meal', 'color': '#009688'},
];

Color _parseColor(String hex) {
  hex = hex.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

IconData _iconFromString(String name) {
  switch (name) {
    case 'local_pizza':
      return Icons.local_pizza;
    case 'breakfast_dining':
      return Icons.breakfast_dining;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'cake':
      return Icons.cake;
    case 'ramen_dining':
      return Icons.ramen_dining;
    case 'set_meal':
      return Icons.set_meal;
    default:
      return Icons.fastfood;
  }
}

class _CatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CatItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PopularItemsGrid extends StatelessWidget {
  const _PopularItemsGrid();

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        List<Product> products;
        if (snapshot.hasError) {
          products = [
            Product(id: 1, name: 'Shawarma Plate', price: 12.99, stockQuantity: 50,
                category: 'Fast Food', imageUrls: ['https://via.placeholder.com/300x300?text=Shawarma'], isSpicy: true),
            Product(id: 2, name: 'Mandi Rice', price: 15.99, stockQuantity: 30,
                category: 'Arabic', imageUrls: ['https://via.placeholder.com/300x300?text=Mandi']),
            Product(id: 3, name: 'Grilled Chicken', price: 18.99, stockQuantity: 25,
                category: 'Grill', imageUrls: ['https://via.placeholder.com/300x300?text=Chicken'], isSpicy: false),
            Product(id: 4, name: 'Fresh Juice', price: 5.99, stockQuantity: 100,
                category: 'Beverages', imageUrls: ['https://via.placeholder.com/300x300?text=Juice']),
          ];
        } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          products = snapshot.data!.docs.map((doc) {
            return Product.fromJson(
                {'id': doc.id, ...doc.data() as Map<String, dynamic>});
          }).toList();
        } else {
          products = [
            Product(id: 1, name: 'Shawarma Plate', price: 12.99, stockQuantity: 50,
                category: 'Fast Food', imageUrls: ['https://via.placeholder.com/300x300?text=Shawarma'], isSpicy: true),
            Product(id: 2, name: 'Mandi Rice', price: 15.99, stockQuantity: 30,
                category: 'Arabic', imageUrls: ['https://via.placeholder.com/300x300?text=Mandi']),
            Product(id: 3, name: 'Grilled Chicken', price: 18.99, stockQuantity: 25,
                category: 'Grill', imageUrls: ['https://via.placeholder.com/300x300?text=Chicken'], isSpicy: false),
            Product(id: 4, name: 'Fresh Juice', price: 5.99, stockQuantity: 100,
                category: 'Beverages', imageUrls: ['https://via.placeholder.com/300x300?text=Juice']),
          ];
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () => _showProductDetail(context, product),
              child: Container(
                decoration: TayyebGoTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          image: product.imageUrls != null &&
                                  product.imageUrls!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(product.imageUrls!.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            if (product.imageUrls == null ||
                                product.imageUrls!.isEmpty)
                              Center(
                                child: Icon(Icons.restaurant,
                                    size: 36,
                                    color: TayyebGoTheme.primaryColor
                                        .withValues(alpha: 0.3)),
                              ),
                            if (product.isSpicy)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: TayyebGoTheme.errorColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.whatshot,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(product.displayCategory,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: TayyebGoTheme.textSecondary)),
                            const Spacer(),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: TayyebGoTheme.primaryColor)),
                                GestureDetector(
                                  onTap: () => cart.addLine(product),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: TayyebGoTheme.primaryColor,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: TayyebGoTheme.bottomSheetDecoration,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        image: product.imageUrls != null &&
                                product.imageUrls!.isNotEmpty
                            ? DecorationImage(
                                image:
                                    NetworkImage(product.imageUrls!.first),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: product.imageUrls == null ||
                              product.imageUrls!.isEmpty
                          ? Center(
                              child: Icon(Icons.restaurant,
                                  size: 60,
                                  color: TayyebGoTheme.primaryColor
                                      .withValues(alpha: 0.3)),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(product.displayName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.isSpicy)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: TayyebGoTheme.errorColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.whatshot,
                                    size: 12,
                                    color: TayyebGoTheme.errorColor),
                                SizedBox(width: 4),
                                Text('Spicy',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: TayyebGoTheme.errorColor)),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: TayyebGoTheme.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(product.displayCategory,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: TayyebGoTheme.primaryColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (product.description != null)
                      Text(product.description!,
                          style: const TextStyle(
                              fontSize: 14,
                              color: TayyebGoTheme.textSecondary)),
                    const SizedBox(height: 24),
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      product.description ??
                          'A delicious ${product.displayName} prepared with the finest ingredients.',
                      style: const TextStyle(
                          fontSize: 14, color: TayyebGoTheme.textSecondary),
                    ),
                    if (product.preparationTime > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 16, color: TayyebGoTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text('${product.preparationTime} min',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: TayyebGoTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: TayyebGoTheme.primaryColor)),
                  const Spacer(),
                  SizedBox(
                    width: 160,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<CartProvider>().addLine(product);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${product.displayName} added to cart'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
