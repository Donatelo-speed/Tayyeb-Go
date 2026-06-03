import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/cart_provider.dart';
import '../models/user_model.dart';
import '../theme/design_tokens.dart';
import '../models/product.dart';
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
import '../widgets/shimmer_loading.dart';
import '../widgets/brand_logo.dart';

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

class _CustomerHomeState extends State<CustomerHome>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _tabCtrl;
  late Animation<double> _tabFade;

  final _screens = const [
    _HomeTab(),
    VendorsScreen(),
    CartScreen(),
    OrdersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = AnimationController(
      duration: TayyebGoTokens.durationFast,
      vsync: this,
    );
    _tabFade = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOut);
    _tabCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    _tabCtrl.reverse().then((_) {
      setState(() => _currentIndex = index);
      _tabCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: TayyebGoColors.background,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              selectedIndex: _currentIndex.clamp(0, 3),
              onDestinationSelected: _switchTab,
              extended: true,
              minExtendedWidth: 200,
              labelType: NavigationRailLabelType.none,
              backgroundColor: TayyebGoColors.surface,
              indicatorColor: TayyebGoColors.primary.withValues(alpha: 0.12),
              selectedIconTheme: const IconThemeData(
                  color: TayyebGoColors.primary, size: 22),
              unselectedIconTheme: IconThemeData(
                  color: TayyebGoColors.textMuted.withValues(alpha: 0.6),
                  size: 22),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: AppLogoMark(size: 44, animate: false),
              ),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home')),
                NavigationRailDestination(
                    icon: Icon(Icons.store_outlined),
                    selectedIcon: Icon(Icons.store_rounded),
                    label: Text('Vendors')),
                NavigationRailDestination(
                    icon: Icon(Icons.shopping_bag_outlined),
                    selectedIcon: Icon(Icons.shopping_bag_rounded),
                    label: Text('Cart')),
                NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: Text('Orders')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: ClipRect(
                child: FadeTransition(
                  opacity: _tabFade,
                  child: _screens[_currentIndex],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: TayyebGoColors.background,
      body: ClipRect(
        child: FadeTransition(
          opacity: _tabFade,
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: TayyebGoColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  active: _currentIndex == 0,
                  onTap: () => _switchTab(0),
                ),
                _NavItem(
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store_rounded,
                  label: 'Vendors',
                  active: _currentIndex == 1,
                  onTap: () => _switchTab(1),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Cart',
                  active: _currentIndex == 2,
                  badge: cart.totalQuantity > 0 ? '${cart.totalQuantity}' : null,
                  onTap: () => _switchTab(2),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  active: _currentIndex == 3,
                  onTap: () => _switchTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: TayyebGoTokens.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? TayyebGoColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active
                      ? TayyebGoColors.primary
                      : TayyebGoColors.textMuted,
                  size: 22,
                ),
                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: TayyebGoColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? TayyebGoColors.primary
                    : TayyebGoColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fade = CurvedAnimation(
        parent: _animCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.displayName ?? 'Guest';

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: TayyebGoColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: TayyebGoGradients.hero,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant_menu_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Tayyeb',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 20)),
                  Text('GO',
                      style: TextStyle(
                          fontWeight: FontWeight.w200,
                          fontSize: 20,
                          color: TayyebGoColors.textMuted)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _HeroBanner(userName: userName),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'Categories'),
                  const SizedBox(height: 14),
                  _CategoryRow(),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'Popular Now'),
                  const SizedBox(height: 14),
                  const _PopularGrid(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String userName;
  const _HeroBanner({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: TayyebGoGradients.heroWarm,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TayyebGoColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hey, $userName!',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('What would you like to eat today?',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CatalogScreen())),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22),
                  const SizedBox(width: 10),
                  Text('Search dishes, restaurants...',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: TayyebGoColors.textPrimary)),
        if (onSeeAll != null)
          TextButton(
              onPressed: onSeeAll,
              child: const Text('See all',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TayyebGoColors.primary)))
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _categories = const [
    {'name': 'Fast Food', 'icon': Icons.fastfood_rounded, 'color': 0xFFFF9800},
    {'name': 'Pizza', 'icon': Icons.local_pizza_rounded, 'color': 0xFFF44336},
    {'name': 'Breakfast', 'icon': Icons.breakfast_dining_rounded, 'color': 0xFFFFC107},
    {'name': 'Coffee', 'icon': Icons.local_cafe_rounded, 'color': 0xFF795548},
    {'name': 'Desserts', 'icon': Icons.cake_rounded, 'color': 0xFFE91E63},
    {'name': 'Noodles', 'icon': Icons.ramen_dining_rounded, 'color': 0xFF9C27B0},
    {'name': 'Seafood', 'icon': Icons.set_meal_rounded, 'color': 0xFF009688},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final color = Color(cat['color'] as int);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CatalogScreen(
                    categoryFilter: cat['name'] as String),
              ),
            ),
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: TayyebGoColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: TayyebGoColors.divider.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat['icon'] as IconData,
                        color: color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(cat['name'] as String,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PopularGrid extends StatelessWidget {
  const _PopularGrid();

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        List<Product> products;
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          products = _fallbackProducts();
        } else {
          products = snapshot.data!.docs
              .map((doc) => Product.fromJson(
                  {'id': doc.id, ...doc.data() as Map<String, dynamic>}))
              .toList();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => SkeletonCard(dark: false, height: 160),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return _ProductCard(product: p, cart: cart);
          },
        );
      },
    );
  }

  List<Product> _fallbackProducts() => [
        Product(
            id: 1,
            name: 'Shawarma Plate',
            price: 12.99,
            stockQuantity: 50,
            category: 'Fast Food',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Shawarma'
            ],
            isSpicy: true),
        Product(
            id: 2,
            name: 'Mandi Rice',
            price: 15.99,
            stockQuantity: 30,
            category: 'Arabic',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Mandi'
            ]),
        Product(
            id: 3,
            name: 'Grilled Chicken',
            price: 18.99,
            stockQuantity: 25,
            category: 'Grill',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Chicken'
            ]),
        Product(
            id: 4,
            name: 'Fresh Juice',
            price: 5.99,
            stockQuantity: 100,
            category: 'Beverages',
            imageUrls: [
              'https://via.placeholder.com/300x300?text=Juice'
            ]),
      ];
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final CartProvider cart;

  const _ProductCard({required this.product, required this.cart});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.imageUrls != null && product.imageUrls!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: TayyebGoColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: TayyebGoColors.divider.withValues(alpha: 0.4)),
          boxShadow: TayyebGoTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrls!.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: hasImage
                      ? null
                      : LinearGradient(
                          colors: [
                            TayyebGoGradients.hero.colors[0]
                                .withValues(alpha: 0.15),
                            TayyebGoGradients.hero.colors[1]
                                .withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Stack(
                  children: [
                    if (!hasImage)
                      Center(
                        child: Icon(Icons.restaurant_rounded,
                            size: 36,
                            color: TayyebGoColors.primary
                                .withValues(alpha: 0.15)),
                      ),
                    if (product.isSpicy)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: TayyebGoColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_fire_department_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
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
                            fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(product.displayCategory,
                        style: const TextStyle(
                            fontSize: 11,
                            color: TayyebGoColors.textMuted)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: TayyebGoColors.primary)),
                        GestureDetector(
                          onTap: () => cart.addLine(product),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: TayyebGoGradients.hero,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
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
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductDetailSheet(
          product: product, cart: cart),
    );
  }
}

class _ProductDetailSheet extends StatelessWidget {
  final Product product;
  final CartProvider cart;

  const _ProductDetailSheet({
    required this.product,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.imageUrls != null && product.imageUrls!.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: TayyebGoColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: TayyebGoTokens.modalShadow,
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TayyebGoColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: TayyebGoColors.primary
                          .withValues(alpha: 0.06),
                    ),
                    child: hasImage
                        ? Image.network(
                            product.imageUrls!.first,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(Icons.restaurant_rounded,
                                size: 64,
                                color: TayyebGoColors.primary
                                    .withValues(alpha: 0.2)),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(product.displayName,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: TayyebGoColors.textPrimary)),
                    ),
                    Text('\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: TayyebGoColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: TayyebGoColors.primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product.displayCategory,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TayyebGoColors.primary)),
                    ),
                    if (product.isSpicy) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TayyebGoColors.error
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                Icons
                                    .local_fire_department_rounded,
                                size: 14,
                                color: TayyebGoColors.error),
                            SizedBox(width: 4),
                            Text('Spicy',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        TayyebGoColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  product.description ??
                      'A delicious ${product.displayName} prepared with the finest ingredients.',
                  style: const TextStyle(
                      fontSize: 14,
                      color: TayyebGoColors.textSecondary,
                      height: 1.6),
                ),
                if (product.preparationTime > 0) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 18,
                          color: TayyebGoColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                          '${product.preparationTime} min preparation',
                          style: const TextStyle(
                              fontSize: 13,
                              color:
                                  TayyebGoColors.textSecondary)),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      cart.addLine(product);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${product.displayName} added to cart'),
                          backgroundColor:
                              TayyebGoColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_rounded,
                        size: 20),
                    label: const Text('Add to Cart',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TayyebGoColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor:
                          TayyebGoColors.primary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}